const logActiveWindow = require('./src/log-active-window.js')
const qpaCheckRun = require('./src/check-and-run-qpas.js')

;( async () => {

  await logActiveWindow()
  const results = await qpaCheckRun()
  console.log('results:', results)

})()
