# تطبيق تسجيل زوار المعرض – الهنا إليكتريك (7i-GEARS)

مجاني بالكامل: الصفحة على **GitHub Pages** أو **Cloudflare Pages**، والبيانات في **Supabase (Postgres)**.

## الملفات
| الملف | الدور |
|---|---|
| `index.html` | التطبيق كله (الشكل + الكود + اللوجو جوّاه) |
| `sw.js` | يخلّي الصفحة تفتح من غير نت بعد أول مرة |
| `manifest.webmanifest` + `icon-192.png` + `icon-512.png` | أيقونة "Add to Home Screen" |
| `schema.sql` | الجدول والصلاحيات في Supabase (مش بيترفع على الموقع) |

## 1) قاعدة البيانات
1. https://supabase.com ← **New project** (اسم مثلاً `elhana-expo`، أقرب منطقة، احفظ كلمة سر القاعدة).
2. **SQL Editor ← New query** ← الصق `schema.sql` ← **Run**. لازم يطلع `Success. No rows returned`.
3. **Authentication ← Users ← Add user ← Create new user**: إيميل + كلمة سر + فعّل **Auto Confirm User**. حساب لكل موظف أو حساب مشترك.
4. **Authentication ← Sign In / Providers**: اقفل **Allow new users to sign up**.
5. **Project Settings ← API Keys**: انسخ **Project URL** و **Publishable key** (أو `anon` key من تبويب Legacy). متستخدمش أبدًا `secret` أو `service_role`.

## 2) ضبط التطبيق
في `index.html` في أول السكريبت التاني:
```js
var SUPABASE_URL = "https://xxxx.supabase.co";
var SUPABASE_ANON_KEY = "sb_publishable_...";   // أو eyJ... لو anon القديم
```

## 3) النشر (ارفع كل الملفات ما عدا schema.sql و README في جذر الريبو)
**GitHub Pages:** New repository ← Upload files ← Settings ← Pages ← Branch `main` / root ← Save ← الرابط `https://USERNAME.github.io/REPO/`.
**Cloudflare Pages:** Workers & Pages ← Create ← Pages ← Connect to Git ← اختار الريبو ← Build command فاضي، Output directory `/` ← Deploy.

## 4) على الموبايلات
افتح الرابط ← سجّل دخول ← **Add to Home Screen**. افتحه مرة واحدة والنت شغال قبل المعرض عشان يتحفظ على الجهاز.

## اختبار سريع قبل المعرض
- سجّل زائر تجريبي ← يظهر في السجل وفي Supabase ← Table Editor ← visitors.
- افتح من موبايلين: اللي يتسجل على واحد يظهر على التاني لوحده خلال ثانية.
- اقفل النت وسجّل زائر ← يظهر "منتظر الرفع" ← افتح النت ← يترفع لوحده.
- جرّب تعديل، تغيير الدرجة، حذف، تصدير.
- امسح البيانات التجريبية من Table Editor.

## ملاحظات
- **صدّر نسخة آخر كل يوم** من زرار "تصدير" (CSV يفتح في Excel بالعربي).
- Supabase المجاني بيوقف المشروع لو ما اتستخدمش أسبوع؛ ادخل عليه قبل المعرض بيوم.
- لو عدّلت `index.html` بعد النشر، ارفع رقم `VERSION` في `sw.js` عشان الموبايلات تاخد النسخة الجديدة.
- الحذف والتعديل محتاجين نت؛ التسجيل بس اللي بيشتغل أوفلاين.
