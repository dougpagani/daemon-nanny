const fs = require('fs').promises
const puppeteer = require("puppeteer")

const LAUNCH_CONFIG = {
  headless: true,
  defaultViewport: null,
  slowMo: 20,
}

const URL = 'https://www.computerhope.com/jargon/program.htm'

;( async () => {

  const browser = await puppeteer.launch(LAUNCH_CONFIG)
  const page = (await browser.pages())[0]

  await page.goto(URL)
  const matches = await page.$x('//tr//a')

  // DOES NOT WORK
  const textMatches = await Promise.all(matches.map( async (elh) => await elh.evaluate( el => el.textContent)))

  console.log('matches:', textMatches)
  // await fs.write('asdf', FILE)
  
  

})()
