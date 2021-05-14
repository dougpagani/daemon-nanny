const fs = require('fs').promises
const child_process = require('child_process');

if (require.main === module) {
  main().then(console.log)
}
async function main() {
  const qpaList  = await parseQpaListFromFile()
  const qpaSpecResults = await Promise.all(
    qpaList.map(processSingleQpa)
  )

  return qpaSpecResults
}

async function parseQpaListFromFile() {
  const qpaFile = await fs.readFile('./qpa-specs/doug', "utf-8")
  const qpaList = qpaFile
    .split('\n')
    .filter(el => ! el.startsWith('#')) // adsf
    .filter(el => el !== '') // empty lines
    .map(parseQpaSpec)

  return qpaList
}

async function processSingleQpa (qpa) {
  const results = {}
  results.query = await executeQpaQuery(qpa.query) 
  results.predicate = executeQpaPredicate(results.query,qpa.predicate)
  if ( results.predicate  === true ) {
    results.action = await executeQpaAction(qpa.action)
  }
  return { spec: qpa, results }
}

function parseQpaSpec(qpaLine) {
  [ query, predicate, action ] = qpaLine.split(';')
  return { query, predicate, action }

// String
// `jq 'select(.app=="Signal")' | jq 'select(.timestamp > "'$(date +%Y-%m-%d)'")' | jq -s length;1===1;echo do nothing`
// -> 
/*
{
   query: `jq 'select(.app=="Signal")' | jq 'select(.timestamp > "'$(date +%Y-%m-%d)'")' | jq -s length`,
   predicate: '1===1',
   action: 'echo "do nothing"',
}
*/
   
}

async function executeQpaQuery(query) {
  // DOCS: https://nodejs.org/api/child_process.html
  let childData = ""

  const queryProm = new Promise( (resolve, reject) => {

    const child = child_process.exec(query)

    // Process Event Configurations
    child.stdout.on('data', data => childData+=data)
    // child.stdout.on('data', console.log)
    child.stderr.on('data', reject)
    child.stderr.on('data', console.error)
    child.on('error', reject)
    child.on('close', () => resolve(childData.trim()))
  })

  return queryProm

  // ALTERNATIVE:
  // https://stackoverflow.com/a/29656103
  // var parse = require('shell-quote').parse;
  // const cmdline = parse(????)
  // child_process.spawn(cmdline[0], cmdline.slice(1), [, options])

  // Alternative for promisifying:
  // let didChildFinish = false
  // function childFinished() { didChildFinish = true }
  // const child = child_process.exec(query, childFinished)
}
function executeQpaPredicate(queryResult, predicate) {
  return eval(queryResult + predicate)
}
function executeQpaAction(action) {
  // This is just a shim layer until they differentiate
  // They should be different functions but at this point they
  // ... don't have different implementations
  // In the future it's imagined that action will have built-in
  // ... actions and query will have built-in query helpers
  return executeQpaQuery(action)
}
// For a fancier invocation, build from here:
// https://gist.github.com/benjamingr/0237932cee84712951a2
process.on('unhandledRejection', (reason) => {
  console.log("\x1b[38;5;1m UPR: ", reason, "\033[0m")
});
