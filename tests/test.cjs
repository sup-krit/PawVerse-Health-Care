const { chromium } = require('D:/Resume/Nestie/node_modules/playwright');
const fs = require('fs');
const assert = require('assert/strict');
const path = require('path');
const {pathToFileURL} = require('url');
const projectRoot=path.resolve(__dirname,'..');
const root=path.join(__dirname,'artifacts');
fs.mkdirSync(root,{recursive:true});
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
 const page=await browser.newPage({viewport:{width:1480,height:1120}});
 const errors=[]; page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.join(projectRoot,'pawverse-health-uiux.html')).href);
 await page.screenshot({path:root+'/desktop.png',fullPage:true});
 const go=async p=>page.locator('#screen-menu [data-act="go:'+p+'"]').click();
 const act=async a=>page.locator('[data-act="'+a+'"]').first().click();
 // All screens must render and have a functional main region.
 for(const p of ['home','timeline','add','vaccines','meds','appointments','weight','labs','allergies','documents','share','shares','verification','emergency','insurance','nutrition','access','notifications']){await go(p);assert((await page.locator('#app-main').innerText()).length>40,p);}
 await go('weight');await act('add:weight');await page.locator('[name=value]').fill('26');await page.locator('#record-form button[type=submit]').click();assert((await page.locator('#app-main').innerText()).includes('26'));assert((await page.locator('#app-main').innerText()).includes('+2.4%'));
 await go('meds');await act('dose:r2:taken');assert(await page.locator('[data-act="dose:r2:taken"]').isDisabled());await act('med-stop:r2');assert((await page.locator('#app-main').innerText()).includes('หยุดแล้ว'));
 await go('appointments');await act('appointment:a1:completed');await act('convert:a1');assert((await page.locator('#app-main').innerText()).includes('ดูบันทึกที่เชื่อมแล้ว'));
 await go('timeline');await act('record:r1');assert(await page.locator('[data-act="delete:r1"]').isDisabled());await act('amend:r1');await page.locator('[name=title]').fill('วัคซีนพิษสุนัขบ้า · ฉบับแก้ไข');await page.locator('#record-form button[type=submit]').click();await go('timeline');assert((await page.locator('#app-main').innerText()).includes('ฉบับแก้ไข'));
 await go('labs');await act('add:lab');await page.locator('[name=title]').fill('Lab no range');await page.locator('[name=test]').fill('Test numeric');await page.locator('[name=result]').fill('12');await page.locator('#record-form button[type=submit]').click();assert((await page.locator('#app-main').innerText()).includes('ไม่มีช่วงอ้างอิงที่ใช้เปรียบเทียบ'));
 await go('share');await page.locator('input[name=records][value=r7]').check();await page.locator('#share-form button').click();await act('confirm-share');assert(await page.locator('#modal').isVisible());await page.locator('#consent-check').check();await act('confirm-share');await page.locator('[data-act^="recipient:"]').click();assert((await page.locator('#modal-body').innerText()).includes('ไก่'));assert(!(await page.locator('#modal-body').innerText()).includes('CBC'));await page.locator('[data-act^="revoke-live:"]').click();assert((await page.locator('#modal-body').innerText()).includes('ไม่มีข้อมูลแสดง'));await act('close');
 await go('emergency');await page.locator('#qr-form button').click();await page.locator('[data-act^="qr-view:"]').first().click();assert((await page.locator('#modal-body').innerText()).includes('ไก่'));await act('close');await act('qr-rotate');await act('qr-view:1');assert((await page.locator('#modal-body').innerText()).includes('Token ถูกเปลี่ยน'));await act('close');
 await page.locator('#demo-role').selectOption('viewer');await go('vaccines');assert(await page.locator('[data-act="add:vaccine"]').isDisabled());await go('share');assert((await page.locator('#app-main').innerText()).includes('Owner เท่านั้น'));
 await page.locator('#demo-role').selectOption('owner');await go('home');await act('pets');await act('pet:pet_luna');assert(!(await page.locator('#app-main').innerText()).includes('CBC'));await act('pets');await act('pet:pet_mochi');
 await go('documents');await page.locator('#doc-record').selectOption('r7');await page.locator('#doc-file').setInputFiles({name:'allergy-demo.pdf',mimeType:'application/pdf',buffer:Buffer.from('%PDF-1.4\nDemo only')});await page.locator('#upload-form button').click();assert((await page.locator('#app-main').innerText()).includes('รอจำลองผลตรวจ'));await page.locator('[data-act^="scan:"][data-act$=":ready"]').click();assert((await page.locator('#app-main').innerText()).includes('พร้อมดูตัวอย่าง'));await act('delete-doc:d1');assert((await page.locator('#toast').innerText()).includes('หลักฐาน'));
 await go('nutrition');await page.locator('[name=stage]').selectOption('senior');await page.locator('[name=neutered]').selectOption('unknown');await page.locator('#nutrition-form button').click();await go('home');await go('nutrition');assert.equal(await page.locator('[name=stage]').inputValue(),'senior');assert.equal(await page.locator('[name=neutered]').inputValue(),'unknown');
 await go('notifications');await page.locator('[name=n0]').uncheck();await page.locator('[name=offset]').selectOption('7');await page.locator('#notify-form button').click();await go('home');await go('notifications');assert.equal(await page.locator('[name=n0]').isChecked(),false);assert.equal(await page.locator('[name=offset]').inputValue(),'7');
 await go('insurance');await act('new-insurance');await page.locator('[name=provider]').fill('Demo Insurance');await page.locator('[name=number]').fill('DEMO1234');await page.locator('[name=coverage]').fill('ข้อมูลจำลอง');await page.locator('[name=expiry]').fill('2026-09-09');await page.locator('#insurance-form button').click();assert((await page.locator('#app-main').innerText()).includes('••••1234'));
 await go('share');await page.locator('input[name=records][value=r7]').check();await page.locator('#share-form button').click();await page.locator('#consent-check').check();await act('confirm-share');await act('advance');await page.locator('[data-act^="recipient:"]').last().click();assert((await page.locator('#modal-body').innerText()).includes('หมดอายุ'));await act('close');await go('insurance');assert((await page.locator('#app-main').innerText()).includes('หมดอายุ'));
 await go('verification');await act('verify:pending');await act('verify:verified');await act('verify:expired');assert((await page.locator('#app-main').innerText()).includes('หมดอายุ'));await act('ai-review');assert(await page.locator('#ai-form').isVisible());await page.locator('[name=confirmed]').check();await page.locator('#ai-form button').click();assert((await page.locator('#app-main').innerText()).includes('AI extracted'));
 for(const mode of ['loading','error','denied','empty']){await page.locator('#demo-state').selectOption(mode);assert((await page.locator('#app-main').innerText()).length>20);await page.locator('[data-act="recover"]').click();}
 await act('reset');await page.waitForTimeout(3600);await page.screenshot({path:root+'/desktop.png',fullPage:true});
 for(const p of ['weight','labs','share','emergency']){await go(p);await page.screenshot({path:root+'/'+p+'.png',fullPage:true});}
 await go('home');
 for(const width of [360,768,1024]){await page.setViewportSize({width,height:900});assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'overflow at '+width);}
 await page.setViewportSize({width:390,height:844});await page.screenshot({path:root+'/mobile.png',fullPage:true});
 assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'mobile horizontal overflow');
 await page.locator('.mobile-switch [data-mobile=docs]').click();assert(await page.locator('.inspector').isVisible());await page.screenshot({path:root+'/mobile-flow.png',fullPage:true});
 await page.locator('.mobile-switch [data-mobile=screens]').click();await go('labs');assert(await page.locator('.stage').isVisible());
 assert.deepEqual(errors,[],'browser errors');
 fs.writeFileSync(root+'/test-results.json',JSON.stringify({passed:true,checks:['18 screens','weight chart + percent','medication idempotency + stop','appointment conversion','verified amendment','lab no range','consent + scoped recipient + revoke + expiry','QR rotate','Viewer permissions','pet isolation','upload scan and retained evidence','nutrition context persists','notification preferences persist','insurance expiry','Phase2 verification and confirmed extraction','empty/loading/error/denied','360/390/768/1024 responsive overflow + navigation'],browserErrors:errors},null,2));
 console.log('PASS: 18 screens and critical interaction journeys; no browser errors');
 await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1});
