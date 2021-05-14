const fs = require('fs').promises
const child_process = require('child_process');

if (require.main === module) {
  main()
}
async function main() {
  const qpaList  = await parseQpaListFromFile()
  console.log(`qpaList (type: ${typeof qpaList}):`, qpaList)
  const dooby = await Promise.all(
    qpaList.map(executeQpaQuery)
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

async function executeQpaQuery(qpa) {
  // DOCS: https://nodejs.org/api/child_process.html
  let childData
  const query = qpa.query

  const queryProm = new Promise( (resolve, reject) => {

    console.log('query:', query)
    const child = child_process.exec(query)

    // Process Event Configurations
    // child.stdout.on('data', data => childData+=data)
    child.stdout.on('data', console.log)
    // child.stderr.on('data', reject)
    child.stderr.on('data', console.error)
    child.on('error', reject)
    child.on('close', () => resolve(childData))
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
function executeQpaPredicate() {
  throw Error('Function Not Yet Implemented')
}
function executeQpaAction() {
  throw Error('Function Not Yet Implemented')
}
// For a fancier invocation, build from here:
// https://gist.github.com/benjamingr/0237932cee84712951a2
process.on('unhandledRejection', (reason) => {
  console.log("\x1b[38;5;1m UPR: ", reason, "\033[0m")
});
