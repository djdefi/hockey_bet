require 'yaml'
require 'json'
require 'open3'

RSpec.describe 'Scheduled workflows' do
  it 'uses the pinned Ruby and grants API failure notifications issue access' do
    workflow = YAML.load_file('.github/workflows/check_api.yml')
    steps = workflow.fetch('jobs').fetch('check-api').fetch('steps')
    setup = steps.find { |step| step['uses']&.start_with?('ruby/setup-ruby@') }
    notification = steps.find { |step| step['uses']&.start_with?('actions/github-script@') }

    expect(setup.fetch('with')).not_to have_key('ruby-version')
    expect(workflow.fetch('permissions').fetch('issues')).to eq('write')
    expect(notification.fetch('if')).to include("steps.check-api.outcome == 'failure'")
  end

  it 'prunes only eligible previews using the injected client and reports deletion failures' do
    workflow = YAML.load_file('.github/workflows/prune-deployments.yml')
    expect(workflow.fetch('permissions').fetch('deployments')).to eq('write')
    scripts = workflow.fetch('jobs').fetch('prune-deployments').fetch('steps')
                      .filter_map { |step| step.dig('with', 'script') }

    output, status = Open3.capture2e('node', '-e', <<~'JS', stdin_data: JSON.generate(scripts))
      const assert = require('node:assert/strict');
      const scripts = JSON.parse(require('node:fs').readFileSync(0, 'utf8'));
      const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
      const [select, remove] = scripts.map(script =>
        new AsyncFunction('github', 'context', 'core', 'require',
          script.replace('${{ github.event.inputs.days_to_keep || 30 }}', '30')));
      const now = new Date().toISOString();
      const old = new Date(Date.now() - 45 * 86400000).toISOString();
      const deployments = [
        { id: 1, environment: 'github-pages', created_at: old },
        { id: 2, environment: 'preview-2', created_at: old },
        { id: 3, environment: 'preview-3', created_at: now },
        { id: 4, environment: 'preview-4', created_at: now }
      ];
      const outputs = {}, errors = [], inactive = [], deleted = [];
      const core = {
        setOutput: (key, value) => outputs[key] = value,
        setFailed: message => errors.push(message)
      };
      const context = { repo: { owner: 'test', repo: 'test' } };
      const github = {
        paginate: async method => {
          assert.equal(method, github.rest.repos.listDeployments);
          return deployments;
        },
        rest: {
          repos: {
            listDeployments: () => {},
            createDeploymentStatus: async value => {
              assert.equal(value.state, 'inactive');
              inactive.push(value.deployment_id);
            },
            deleteDeployment: async value => deleted.push(value.deployment_id)
          },
          pulls: { get: async ({ pull_number }) =>
            ({ data: { state: pull_number === 4 ? 'closed' : 'open' } }) }
        }
      };
      (async () => {
        await select(github, context, core, require);
        assert.deepEqual(JSON.parse(outputs.deployments_to_delete).map(d => d.id), [2, 4]);
        process.env.DEPLOYMENTS_TO_DELETE = outputs.deployments_to_delete;
        await remove(github, context, core, require);
        assert.deepEqual(inactive, [2, 4]);
        assert.deepEqual(deleted, [2, 4]);
        assert.deepEqual(errors, []);
        github.rest.repos.deleteDeployment = async () => { throw new Error('Forbidden'); };
        await remove(github, context, core, require);
        assert.deepEqual(errors, ['2 deployments could not be deleted']);
      })().catch(error => { console.error(error); process.exitCode = 1; });
    JS
    expect(status.success?).to be(true), output
  end
end
