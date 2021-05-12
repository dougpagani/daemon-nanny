/* this is our snapshots/event stream of computer activity */
const activeWindow = require('active-win');
const fs = require('fs').promises
const ACTIVITY_LOG_FILEPATH = require('path').join(require('os').homedir(), '.nanny-activity-log')

async function main() {
  const rawWindowInfo = await getActiveWindowInfo()
  const logEntryData = buildLogEntryFromRawInfo(rawWindowInfo)
  console.log(logEntryData)
  await appendLogEntryToLogFile(logEntryData)
}

async function appendLogEntryToLogFile(logEntryData) {
  const logEntryLine = JSON.stringify(logEntryData) + '\n'
  await fs.appendFile(ACTIVITY_LOG_FILEPATH, logEntryLine)
}

async function getActiveWindowInfo() {
  return await activeWindow()
}

function getTimeStamp() {
  return new Date();
  // e.g. 2021-05-12T20:37:51.243Z
}

// TODO: build with ts type definitions
function buildLogEntryFromRawInfo(rawActiveWindowInfo) {

  // TODO: blacklist values instead; copy-over and start modifiying 
  // ... that way, you dont lose any special values like for example chrome has
  const activeWindowLogEntry = {
    timestamp: getTimeStamp(),
    title: rawActiveWindowInfo.title,
    app: rawActiveWindowInfo.owner.name,
    url: rawActiveWindowInfo.url,
  }
  return activeWindowLogEntry

  // FROM THIS:
	/*
	{
		title: 'Unicorns - Google Search',
		id: 5762,
		bounds: {
			x: 0,
			y: 0,
			height: 900,
			width: 1440
		},
		owner: {
			name: 'Google Chrome',
			processId: 310,
			bundleId: 'com.google.Chrome',
			path: '/Applications/Google Chrome.app'
		},
		url: 'https://sindresorhus.com/unicorn',
		memoryUsage: 11015432
	}
	*/
  // TO THIS:
	/*
	{
                timestamp: SOME_PLEASING_FORMAT,
		title: 'Unicorns - Google Search',
                app: 'Google Chrome',
		url: 'https://sindresorhus.com/unicorn',
	}
	*/
}

if (require.main === module) {
  main()
}


// For a fancier invocation, build from here:
// https://gist.github.com/benjamingr/0237932cee84712951a2
process.on('unhandledRejection', (reason) => {
  console.log("\x1b[38;5;1m UPR: ", reason)
});
