module.exports = {
  branches: ["master"],
  repositoryUrl: "https://github.com/jayal13/NEBo-task",
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/npm",
      {
        npmPublish: false
      }
    ],
    [
      "@semantic-release/changelog",
      {
        changelogFile: "CHANGELOG.md"
      }
    ],
    "@semantic-release/git",
    "@semantic-release/github"
  ]
};