const puppeteer = require('puppeteer');

const title = process.argv[2];
const format = process.argv[3];
const landscape = process.argv[4] === 'true';
const pageIndex = parseInt(process.argv[5]);
const basePath = process.argv[6].replace(/$\/+/, '');
const noSandbox = process.argv[7] == 'true';

(async() => {

    // if (landscape) {
    //     width_sm = 200;
    //     height_sm = Math.floor(width_sm * ratio);
    //     width_xl = 400;
    //     height_xl = Math.floor(width_xl * ratio);
    // } else {
    //     height_sm = 200;
    //     width_sm = Math.floor(height_sm * ratio);
    //     height_xl = 400;
    //     width_xl = Math.floor(height_xl * ratio);
    // }
    // console.log(landscape, ratio, width_sm, height_sm);

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

    // await page.setViewport({
    //         width: width_xl,
    //         height: height_xl,
    //         deviceScaleFactor: 1,
    //     })

    await page.screenshot({
        path: `${basePath}/${title}-RASTER-p${pageIndex}.png`,
        fullPage: true,
        deviceScaleFactor: 2
    })

    // await page.setViewport({
    //         width: width_sm,
    //         height: height_sm,
    //         deviceScaleFactor: 2,
    //     })
    //
    // await page.screenshot({
    //     path: `${basePath}/public/thumbnails/${title}-sm.png`
    // })

    await browser.close();
})();
