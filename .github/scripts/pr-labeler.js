const documentationFilePattern = /\.(md|txt|rst|adoc)$/i

module.exports = async function classifyPullRequest({ github, context, core }) {
  const pullRequest = context.payload.pull_request

  if (!pullRequest) {
    throw new Error('pr-labeler requires a pull_request event')
  }

  const { owner, repo } = context.repo
  const pull_number = pullRequest.number

  async function listCurrentLabels() {
    const labels = await github.paginate(github.rest.issues.listLabelsOnIssue, {
      owner,
      repo,
      issue_number: pull_number,
      per_page: 100
    })

    return labels.map((label) => label.name)
  }

  async function setExclusiveLabel(prefix, desired) {
    const labels = await listCurrentLabels()
    const staleLabels = labels.filter(
      (label) => label.startsWith(`${prefix}:`) && label !== desired
    )

    for (const label of staleLabels) {
      await github.rest.issues.removeLabel({
        owner,
        repo,
        issue_number: pull_number,
        name: label
      })
    }

    if (!labels.includes(desired)) {
      await github.rest.issues.addLabels({
        owner,
        repo,
        issue_number: pull_number,
        labels: [desired]
      })
    }
  }

  const files = await github.paginate(github.rest.pulls.listFiles, {
    owner,
    repo,
    pull_number,
    per_page: 100
  })

  await classifySize(files, setExclusiveLabel, core)
  await classifyRisk(files, listCurrentLabels, setExclusiveLabel, core)
  await classifyTier(pullRequest.user.login, github, owner, repo, setExclusiveLabel, core)
}

async function classifySize(files, setExclusiveLabel, core) {
  const total = files
    .filter((file) => !documentationFilePattern.test(file.filename))
    .reduce((sum, file) => sum + file.changes, 0)

  let label

  if (total < 10) {
    label = 'size: XS'
  } else if (total < 50) {
    label = 'size: S'
  } else if (total < 200) {
    label = 'size: M'
  } else if (total < 500) {
    label = 'size: L'
  } else {
    label = 'size: XL'
  }

  core.info(`Size: ${total} changed lines -> ${label}`)
  await setExclusiveLabel('size', label)
}

async function classifyRisk(files, listCurrentLabels, setExclusiveLabel, core) {
  const labels = await listCurrentLabels()

  if (labels.includes('risk: manual')) {
    core.info('Risk: skipped (manual override)')
    return
  }

  let risk = 'low'

  for (const file of files) {
    const filename = file.filename

    if (filename.includes('secret') || filename.includes('auth') ||
        filename.includes('credential') || filename.includes('permission') ||
        filename.includes('migration') || filename.includes('schema')) {
      risk = 'high'
      break
    }

    if (filename.startsWith('.github/workflows/') || filename.endsWith('.yml')) {
      risk = 'medium'
    }
  }

  core.info(`Risk: ${risk}`)
  await setExclusiveLabel('risk', `risk: ${risk}`)
}

async function classifyTier(author, github, owner, repo, setExclusiveLabel, core) {
  let permission = 'none'

  try {
    const response = await github.rest.repos.getCollaboratorPermissionLevel({
      owner,
      repo,
      username: author
    })
    permission = response.data.permission
  } catch (error) {
    if (error.status !== 404) {
      core.warning(`Could not read collaborator permission for ${author}: ${error.message}`)
    }
  }

  let label

  if (['admin', 'maintain', 'write'].includes(permission)) {
    label = 'tier: maintainer'
  } else {
    const query = `repo:${owner}/${repo} is:pr is:merged author:${author}`
    const response = await github.rest.search.issuesAndPullRequests({
      q: query,
      per_page: 1
    })

    label = response.data.total_count === 0 ? 'tier: first-time' : 'tier: contributor'
  }

  core.info(`Tier: ${author} -> ${label}`)
  await setExclusiveLabel('tier', label)
}
