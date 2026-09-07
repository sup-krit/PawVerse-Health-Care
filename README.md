# PawVerse Health Care — Flutter mobile demo

The mobile implementation now lives in lib/. See [Flutter run instructions](docs/FLUTTER.md) and [milestone scope](docs/MILESTONE.md). The HTML prototype and its prior test artifacts below remain design references, not the mobile product.

# PawVerse Health Care — Interactive Prototype

ไฟล์เปิดใช้งาน: [pawverse-health-uiux.html](pawverse-health-uiux.html)

เปิด HTML ด้วย browser ได้โดยตรง ไม่ต้องติดตั้ง package หรือเปิด server ไฟล์เดียวรวม stylesheet, JavaScript, illustration และ icons ไว้แล้ว อ้างอิง layout และ visual shell จาก `C:/Users/User/orca/workspaces/Resume/amphipod/pawverse-uiux.html`

## ทดลองใช้งาน

- เลือก 18 หน้าจอทางซ้าย; มือถือเลือกแท็บ “หน้าจอ”
- เพิ่มน้ำหนักแล้วดูกราฟและ % change; สลับ Mochi / Luna เพื่อทดลอง pet isolation และข้อมูลเริ่มต้นว่าง
- เพิ่มยา บันทึกให้แล้ว/ข้าม หยุดรายการ และดูสถานะที่เปลี่ยน
- Complete appointment แล้วสร้างบันทึกที่เชื่อมกัน; เปิด verified record แล้วสร้าง amendment
- เพิ่มผลแล็บแบบตัวเลข/ข้อความ มีหรือไม่มี supplied reference range
- แนบชื่อไฟล์จำลอง เลือกผล scan พร้อมดู retention denial ของ verified evidence
- แชร์บันทึกโดยเลือก scope → preview → consent → เปิดมุมมองผู้รับ → ถอนสิทธิ์; ใช้ +8 วันทดลอง expiry
- เปิด Emergency Card แล้วลอง token rotation/revoke และ token เก่า
- ใช้ตัวสลับ Owner / Co-owner / Viewer และสถานะ Empty / Loading / Error / Denied ด้านขวา
- เลือกแท็บ Flow / ทุกฟังก์ชัน / ระบบ & ข้อมูล เพื่อดูแผนภาพและ interaction trace

## ขอบเขตจริงของเดโม

ข้อมูลทั้งหมดเป็น fixture และ state ในหน่วยความจำ รีโหลดหรือเริ่มเดโมใหม่จะคืนค่า ไม่มี backend, network request, persistent storage, notification delivery, file upload/scan จริง, Vet verification หรือ AI จริง การแนบไฟล์อ่านเฉพาะชื่อ/ขนาด/type; ไม่อ่านหรือส่ง bytes QR เป็นภาพจำลองพร้อมปุ่มเปิด limited view ไม่ใช่ QR ที่สแกนด้วยกล้องได้

สิทธิ์ใน HTML ใช้สาธิต UX เท่านั้น ไม่ใช่ security boundary สำหรับข้อมูลจริง BCS/rapid-weight threshold และสูตร nutrition ยังรอ policy จึงไม่แสดงค่าที่แต่งขึ้น Verification workflow และ AI review ติดป้าย Phase 2 / release decision ตาม DEC-01

## การตรวจ

ทดสอบด้วย Chrome headless ผ่าน Playwright ที่ติดตั้งใน workspace ตรวจ 18 หน้าจอและ critical journeys ใน `tests/test.cjs` ผลอยู่ `tests/artifacts/test-results.json` ตรวจภาพ desktop, mobile, Weight, Labs, Share และ Emergency; ตรวจ horizontal overflow ที่ 360/390/768/1024 px ไม่มี browser JavaScript error ในชุดทดสอบ

คำสั่ง rebuild สำหรับ workspace นี้:

```powershell
node 'D:\Resume\PawVerse Health Care\scripts\build.cjs'
node 'D:\Resume\PawVerse Health Care\tests\test.cjs'
```

`scripts/build.cjs` ใช้ assets ใน `src/` ทั้งหมด ไม่ต้องมีไฟล์อ้างอิงใน Orca; HTML ที่ส่งมอบเปิดได้โดยไม่พึ่ง source directory ส่วน tests ใช้ Playwright ที่ติดตั้งใน `D:/Resume/Nestie/node_modules` และ Chrome บนเครื่องนี้

## โครงสร้างโปรเจกต์

```text
PawVerse Health Care/
  pawverse-health-uiux.html   เปิด prototype
  README.md                  วิธีใช้งาน
  src/                       JavaScript, CSS และ SVG ทั้งหมด
  scripts/build.cjs          รวมเป็น standalone HTML
  tests/test.cjs             ตรวจ flow และ responsive
  tests/artifacts/           ภาพตรวจงานและผลทดสอบ
```

PRD และ design handoff อยู่ที่ [Docs/PawVerse Health Care](../Docs/PawVerse%20Health%20Care/review/README.md)
