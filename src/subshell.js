const fs = require('fs').promises
const child_process = require('child_process');

if (require.main === module) {
  main()
}
async function main() {
  const qpaList  = await parseQpaListFromFile()
  console.log(`qpaList (type: ${typeof qpaList}):`, qpaList)
  const dooby = await Promise.all(
    qpaList.map(processSingleQpa)
  )
  console.log('dooby:', dooby)
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
  const queryResult = await executeQpaQuery(qpa.query) 
  const predicateResult = executeQpaPredicate(queryResult,qpa.predicate)
  return predicateResult
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
function executeQpaAction() {
  throw Error('Function Not Yet Implemented')
}
// For a fancier invocation, build from here:
// https://gist.github.com/benjamingr/0237932cee84712951a2
process.on('unhandledRejection', (reason) => {
  console.log("\x1b[38;5;1m UPR: ", reason, "\033[0m")
});
