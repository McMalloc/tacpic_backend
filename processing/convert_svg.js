const puppeteer = require('puppeteer');

const title = process.argv[2];
const width = parseInt(process.argv[3]);
const height = parseInt(process.argv[4]);
const basePath = process.argv[5].replace(/$\/+/, '');

let format, landscape,
    width_sm, height_sm, width_xl, height_xl;

(async() => {
    switch (true) {
        case (width === 297 && height === 420) :
            format = "A3";
            landscape = false;
            break;
        case (width === 420 && height === 297) :
            format = "A3";
            landscape = true;
            break;
        case (width === 297 && height === 210) :
            format = "A4";
            landscape = true;
            break;
        default:
            format = "A4";
            landscape = false;
    }

    const ratio = height / width;

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
        args: ["--disable-gpu"], // makes startup faster
    });
    const page = await browser.newPage();
    await page.goto(`file:${basePath}/files/${title}-VECTOR.svg`);

    await page.pdf({
        path: `${basePath}/files/${title}-PRINT.pdf`,
        format, landscape,
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
        path: `${basePath}/files/${title}-RASTER.png`,
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