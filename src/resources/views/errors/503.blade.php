<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sistem Sedang Diperbarui — {{ config('school.name', 'Floz LMS') }}</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background: #f0f4ff;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
        }
        .card {
            background: white;
            border-radius: 1rem;
            box-shadow: 0 4px 24px rgba(0,0,0,0.08);
            max-width: 480px;
            width: 100%;
            padding: 2.5rem 2rem;
            text-align: center;
        }
        .logo-bar {
            width: 56px;
            height: 6px;
            background: #f97316;
            border-radius: 3px;
            margin: 0 auto 1.25rem;
        }
        .school-name {
            font-size: 0.875rem;
            font-weight: 600;
            color: #6b7280;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 0.5rem;
        }
        h1 {
            font-size: 1.5rem;
            font-weight: 700;
            color: #1e3a5f;
            margin-bottom: 0.75rem;
        }
        p {
            color: #6b7280;
            line-height: 1.6;
            margin-bottom: 0.5rem;
        }
        .eta {
            background: #fff7ed;
            border: 1px solid #fed7aa;
            border-radius: 0.5rem;
            padding: 0.75rem 1rem;
            color: #c2410c;
            font-size: 0.9rem;
            margin-top: 1.25rem;
        }
        .contact {
            margin-top: 1.5rem;
            font-size: 0.8rem;
            color: #9ca3af;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="logo-bar"></div>
        <div class="school-name">{{ config('school.name', 'SDN Kelapadua IV') }} — Floz LMS</div>
        <h1>Sistem Sedang Diperbarui</h1>
        <p>
            Kami sedang melakukan pembaruan sistem untuk meningkatkan
            pengalaman belajar Anda.
        </p>
        <p>
            Mohon bersabar, sistem akan segera kembali normal.
        </p>
        <div class="eta">
            Perkiraan selesai: beberapa menit lagi.<br>
            Silakan coba kembali dalam 5–10 menit.
        </div>
        <div class="contact">
            Butuh bantuan? Hubungi operator sekolah.
        </div>
    </div>
</body>
</html>
