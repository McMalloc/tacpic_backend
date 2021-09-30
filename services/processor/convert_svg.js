const puppeteer = require('puppeteer');

const title = process.argv[2];
const format = process.argv[3];
const landscape = process.argv[4] === 'true';
const pageIndex = parseInt(process.argv[5]);
const basePath = process.argv[6].replace(/$\/+/, '');

(async() => {

    const browser = await puppeteer.launch({
        args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-gpu"], // makes startup faster
    });
    const page = await browser.newPage();
    await page.goto(`file:${basePath}/${title}-VECTOR-p${pageIndex}.svg`);

    await page.pdf({
        path: `${basePath}/${title}-PRINT-p${pageIndex}.pdf`,
        format, landscape, pageRanges: "1", 
        margin: {
            top: "0",
            left: "0",
            right: "0",
            bottom: "0"
        }
    });

    await page.screenshot({
        path: `${basePath}/${title}-RASTER-p${pageIndex}.png`,
        fullPage: true,
        deviceScaleFactor: 2
    })

    await browser.close();
})();
