#define UNICODE
#define _UNICODE

#include <windows.h>
#include <shellapi.h>
#include <cmath>
#include <ctime>
#include <string>
#include <vector>
#include <algorithm>

static const int VIEW_W = 1280;
static const int VIEW_H = 720;
static const float PI = 3.1415926535f;

struct Vec2 {
    float x = 0;
    float y = 0;
};

static float rnd(float a, float b) {
    return a + (float)rand() / (float)RAND_MAX * (b - a);
}

static float len(Vec2 v) {
    return sqrtf(v.x * v.x + v.y * v.y);
}

static Vec2 norm(Vec2 v) {
    float l = len(v);
    if (l < 0.001f) return {0, 0};
    return {v.x / l, v.y / l};
}

static float dist(Vec2 a, Vec2 b) {
    return len({a.x - b.x, a.y - b.y});
}

static COLORREF RGBF(int r, int g, int b) {
    return RGB(r, g, b);
}

enum class ObjKind { Food, Hazard, Bonus };
enum class ObjType { Candy, Bug, Butterfly, Cake, Lollipop, Pepper, Acid, DoubleMagnet, Shield, Slow, Beacon };

struct Obj {
    ObjKind kind = ObjKind::Food;
    ObjType type = ObjType::Candy;
    Vec2 p;
    Vec2 v;
    float r = 12;
    int points = 10;
    int penalty = 0;
    bool touchedByMagnet = false;
    float spin = 0;
};

struct Particle {
    Vec2 p;
    Vec2 v;
    float life = 1;
    float r = 3;
    COLORREF color = RGB(255, 255, 255);
};

struct Boss {
    bool active = false;
    int type = 1;
    Vec2 p;
    float hp = 500;
    float maxHp = 500;
    float t = 0;
};

struct Game {
    int level = 1;
    int wave = 1;
    int score = 0;
    int eaten = 0;
    int poisoned = 0;
    int combo = 0;
    float comboTimer = 0;
    float waveTime = 45;
    float waveTotal = 45;
    float messageTimer = 2;
    std::wstring message = L"EDIBLE PLANET";
    float shake = 0;
    bool gameOver = false;
    Vec2 planet = {640, 420};
    Vec2 tilt = {0, 0};
    float shield = 0;
    float slow = 0;
    float beacon = 0;
    std::vector<Obj> objects;
    std::vector<Particle> particles;
    Boss boss;
};

static Game G;
static HWND g_hwnd = nullptr;
static bool keyState[256] = {};
static Vec2 mouse = {640, 360};
static bool mouseAttract = false;
static bool mouseRepel = false;
static LARGE_INTEGER freq;
static LARGE_INTEGER lastCounter;

static void Burst(Vec2 p, COLORREF color, int count) {
    for (int i = 0; i < count; ++i) {
        float a = rnd(0, PI * 2);
        float s = rnd(80, 320);
        Particle q;
        q.p = p;
        q.v = {cosf(a) * s, sinf(a) * s};
        q.life = rnd(0.25f, 0.9f);
        q.r = rnd(2, 6);
        q.color = color;
        G.particles.push_back(q);
    }
}

static Vec2 EdgePos() {
    float a = rnd(0, PI * 2);
    return {640 + cosf(a) * 760, 420 + sinf(a) * 760};
}

static void TowardPlanet(Obj& o, float speed) {
    float a = atan2f(G.planet.y - o.p.y, G.planet.x - o.p.x) + rnd(-0.35f, 0.35f);
    o.v = {cosf(a) * speed, sinf(a) * speed};
}

static void SpawnFood(float difficulty) {
    float roll = rnd(0, 1);
    Obj o;
    o.kind = ObjKind::Food;
    o.p = EdgePos();
    if (roll < 0.15f) { o.type = ObjType::Cake; o.r = 24; o.points = 50; TowardPlanet(o, 45); }
    else if (roll < 0.38f) { o.type = ObjType::Bug; o.r = 12; o.points = 15; float a = rnd(0, PI * 2); o.p = {G.planet.x + cosf(a) * 150, G.planet.y + sinf(a) * 150}; o.v = {rnd(-55, 55), rnd(-55, 55)}; }
    else if (roll < 0.58f) { o.type = ObjType::Butterfly; o.r = 14; o.points = 25; TowardPlanet(o, 80 * difficulty); }
    else { o.type = ObjType::Candy; o.r = 11; o.points = 10; TowardPlanet(o, rnd(75, 140) * difficulty); }
    G.objects.push_back(o);
}

static void SpawnHazard(float difficulty) {
    float roll = rnd(0, 1);
    Obj o;
    o.kind = ObjKind::Hazard;
    o.p = EdgePos();
    if (roll < 0.28f) { o.type = ObjType::Acid; o.r = 13; o.penalty = 30; float a = rnd(0, PI * 2); o.p = {G.planet.x + cosf(a) * 160, G.planet.y + sinf(a) * 160}; }
    else if (roll < 0.56f) { o.type = ObjType::Pepper; o.r = 16; o.penalty = 20; TowardPlanet(o, 125 * difficulty); }
    else { o.type = ObjType::Lollipop; o.r = 10; o.penalty = 15; TowardPlanet(o, 190 * difficulty); }
    G.objects.push_back(o);
}

static void SpawnBonus() {
    Obj o;
    o.kind = ObjKind::Bonus;
    o.p = EdgePos();
    o.r = 17;
    int t = rand() % 4;
    o.type = t == 0 ? ObjType::DoubleMagnet : t == 1 ? ObjType::Shield : t == 2 ? ObjType::Slow : ObjType::Beacon;
    TowardPlanet(o, 70);
    G.objects.push_back(o);
}

static void StartWave() {
    G.objects.clear();
    G.messageTimer = 2.0f;
    if (G.wave == 10) {
        G.waveTime = G.waveTotal = 85.0f;
        G.message = L"BOSS WAVE!";
        G.boss.active = true;
        G.boss.type = G.level;
        G.boss.p = {640, -100};
        G.boss.maxHp = 380.0f + G.level * 320.0f;
        G.boss.hp = G.boss.maxHp;
        G.boss.t = 0;
        return;
    }
    G.boss.active = false;
    G.waveTime = G.waveTotal = max(28.0f, 50.0f - G.wave * 1.2f - G.level * 2.0f);
    G.message = L"LEVEL " + std::to_wstring(G.level) + L"  WAVE " + std::to_wstring(G.wave);
    float difficulty = 1.0f + G.level * 0.35f + G.wave * 0.08f;
    int food = 14 + G.wave * 3 + G.level * 5;
    int bad = 3 + G.wave + G.level * 2;
    for (int i = 0; i < food; ++i) SpawnFood(difficulty);
    for (int i = 0; i < bad; ++i) SpawnHazard(difficulty);
    if (G.wave % 3 == 0) SpawnBonus();
}

static void ResetGame() {
    G = Game();
    StartWave();
}

static void NextWave() {
    G.wave++;
    if (G.wave > 10) {
        G.level++;
        G.wave = 1;
        if (G.level > 3) {
            G.gameOver = true;
            G.message = L"VICTORY! SCORE " + std::to_wstring(G.score);
            G.messageTimer = 9999;
            return;
        }
    }
    StartWave();
}

static void EatObject(size_t i) {
    Obj& o = G.objects[i];
    bool combo = o.touchedByMagnet || ((fabsf(G.tilt.x) + fabsf(G.tilt.y)) > 0.35f && (mouseAttract || mouseRepel));
    if (combo) {
        G.combo++;
        G.comboTimer = 3.0f;
        G.message = L"COMBO x" + std::to_wstring(min(8, 1 + G.combo));
        G.messageTimer = 0.9f;
        Burst(o.p, RGBF(255, 120, 210), 24);
    }
    int multiplier = combo ? min(8, 1 + G.combo) : 1;
    G.score += o.points * multiplier;
    G.eaten++;
    Burst(o.p, RGBF(255, 210, 90), 14);
    G.objects.erase(G.objects.begin() + i);
}

static void PoisonObject(size_t i) {
    Obj& o = G.objects[i];
    if (G.shield > 0) {
        Burst(o.p, RGBF(120, 220, 255), 14);
        G.objects.erase(G.objects.begin() + i);
        return;
    }
    G.score = max(0, G.score - o.penalty);
    G.poisoned++;
    G.combo = 0;
    G.comboTimer = 0;
    G.shake = 12;
    Burst(o.p, RGBF(255, 60, 40), 20);
    G.objects.erase(G.objects.begin() + i);
}

static void BonusObject(size_t i) {
    Obj& o = G.objects[i];
    if (o.type == ObjType::Shield) { G.shield = 8; G.message = L"BONUS: SHIELD"; }
    else if (o.type == ObjType::Slow) { G.slow = 8; G.message = L"BONUS: SLOW TIME"; }
    else if (o.type == ObjType::Beacon) { G.beacon = 10; G.message = L"BONUS: BEACON"; }
    else { G.beacon = 6; G.shield = 4; G.message = L"BONUS: DOUBLE POWER"; }
    G.messageTimer = 1.4f;
    Burst(o.p, RGBF(255, 220, 40), 30);
    G.objects.erase(G.objects.begin() + i);
}

static void UpdateBoss(float dt) {
    Boss& b = G.boss;
    b.t += dt;
    b.p.x = 640 + sinf(b.t * 0.9f) * 250;
    b.p.y += (b.p.y < 145 ? 65 : sinf(b.t * 1.3f) * 25) * dt;

    if (mouseAttract && dist(mouse, b.p) < 200) {
        b.hp -= 95 * dt;
        G.score += (int)(180 * dt);
        if ((rand() % 20) == 0) SpawnFood(1.5f);
    }

    float attackPeriod = max(0.75f, 1.45f - b.type * 0.18f);
    if (fmodf(b.t, attackPeriod) < dt) {
        for (int i = 0; i < b.type + 1; ++i) SpawnHazard(1.0f + b.type * 0.45f);
    }

    if (b.hp <= 0) {
        Burst(b.p, RGBF(255, 90, 220), 90);
        G.score += 1000;
        b.active = false;
        NextWave();
    }
}

static void Update(float rawDt) {
    if (G.gameOver) return;
    float dt = rawDt * (G.slow > 0 ? 0.55f : 1.0f);

    G.tilt = {0, 0};
    if (keyState['A']) G.tilt.x -= 1;
    if (keyState['D']) G.tilt.x += 1;
    if (keyState['W']) G.tilt.y -= 1;
    if (keyState['S']) G.tilt.y += 1;
    float tl = len(G.tilt);
    if (tl > 1) G.tilt = {G.tilt.x / tl, G.tilt.y / tl};

    if (G.comboTimer > 0) {
        G.comboTimer -= dt;
        if (G.comboTimer <= 0) G.combo = 0;
    }
    if (G.shield > 0) G.shield -= dt;
    if (G.slow > 0) G.slow -= dt;
    if (G.beacon > 0) G.beacon -= dt;
    if (G.messageTimer > 0) G.messageTimer -= dt;
    if (G.shake > 0) G.shake -= dt * 20;

    G.waveTime -= dt;
    if (G.waveTime <= 0 && !G.boss.active) NextWave();

    for (Obj& o : G.objects) {
        Vec2 toPlanet = {G.planet.x - o.p.x, G.planet.y - o.p.y};
        Vec2 np = norm(toPlanet);
        o.v.x += np.x * 18 * dt;
        o.v.y += np.y * 18 * dt;
        o.v.x += G.tilt.x * 160 * dt;
        o.v.y += G.tilt.y * 160 * dt;

        float md = dist(mouse, o.p);
        float radius = mouseAttract ? 145 : mouseRepel ? 170 : 0;
        if (radius > 0 && md < radius) {
            Vec2 d = norm({mouse.x - o.p.x, mouse.y - o.p.y});
            float power = (1.0f - md / radius) * (mouseAttract ? 520.0f : -620.0f);
            o.v.x += d.x * power * dt;
            o.v.y += d.y * power * dt;
            o.touchedByMagnet = true;
        }

        if (G.beacon > 0) {
            float bd = dist(G.planet, o.p);
            if (bd < 260) {
                Vec2 d = norm({G.planet.x - o.p.x, G.planet.y - o.p.y});
                o.v.x += d.x * 360 * dt;
                o.v.y += d.y * 360 * dt;
            }
        }

        if (o.type == ObjType::Bug || o.type == ObjType::Acid) {
            float a = atan2f(o.p.y - G.planet.y, o.p.x - G.planet.x) + PI / 2;
            o.v.x += cosf(a) * 35 * dt;
            o.v.y += sinf(a) * 35 * dt;
        }

        o.p.x += o.v.x * dt;
        o.p.y += o.v.y * dt;
        o.v.x *= 0.995f;
        o.v.y *= 0.995f;
        o.spin += dt * 4;
    }

    for (int i = (int)G.objects.size() - 1; i >= 0; --i) {
        Obj& o = G.objects[i];
        if (dist(o.p, G.planet) < 102 + o.r) {
            if (o.kind == ObjKind::Food) EatObject((size_t)i);
            else if (o.kind == ObjKind::Hazard) PoisonObject((size_t)i);
            else BonusObject((size_t)i);
        } else if (o.p.x < -900 || o.p.x > 2200 || o.p.y < -1000 || o.p.y > 1800) {
            G.objects.erase(G.objects.begin() + i);
        }
    }

    if (G.boss.active) UpdateBoss(dt);

    for (int i = (int)G.particles.size() - 1; i >= 0; --i) {
        Particle& p = G.particles[i];
        p.life -= dt;
        p.p.x += p.v.x * dt;
        p.p.y += p.v.y * dt;
        if (p.life <= 0) G.particles.erase(G.particles.begin() + i);
    }
}

static void FillEllipse(HDC hdc, float x, float y, float rx, float ry, COLORREF color) {
    HBRUSH b = CreateSolidBrush(color);
    HGDIOBJ old = SelectObject(hdc, b);
    Ellipse(hdc, (int)(x - rx), (int)(y - ry), (int)(x + rx), (int)(y + ry));
    SelectObject(hdc, old);
    DeleteObject(b);
}

static void StrokeEllipse(HDC hdc, float x, float y, float rx, float ry, COLORREF color, int width) {
    HPEN p = CreatePen(PS_SOLID, width, color);
    HBRUSH b = (HBRUSH)GetStockObject(NULL_BRUSH);
    HGDIOBJ oldP = SelectObject(hdc, p);
    HGDIOBJ oldB = SelectObject(hdc, b);
    Ellipse(hdc, (int)(x - rx), (int)(y - ry), (int)(x + rx), (int)(y + ry));
    SelectObject(hdc, oldP);
    SelectObject(hdc, oldB);
    DeleteObject(p);
}

static void DrawTextAt(HDC hdc, int x, int y, const std::wstring& text, int size, COLORREF color, bool center = false) {
    HFONT font = CreateFontW(size, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, DEFAULT_PITCH, L"Arial");
    HGDIOBJ old = SelectObject(hdc, font);
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, color);
    RECT r = {x, y, x + 900, y + 80};
    DrawTextW(hdc, text.c_str(), -1, &r, center ? DT_CENTER : DT_LEFT);
    SelectObject(hdc, old);
    DeleteObject(font);
}

static void DrawObject(HDC hdc, const Obj& o) {
    COLORREF c = RGBF(255, 120, 180);
    if (o.kind == ObjKind::Food) {
        if (o.type == ObjType::Bug) c = RGBF(80, 240, 100);
        else if (o.type == ObjType::Butterfly) c = RGBF(140, 80, 30);
        else if (o.type == ObjType::Cake) c = RGBF(255, 238, 180);
    } else if (o.kind == ObjKind::Hazard) {
        if (o.type == ObjType::Acid) c = RGBF(70, 255, 70);
        else if (o.type == ObjType::Pepper) c = RGBF(255, 120, 20);
        else c = RGBF(255, 40, 70);
    } else c = RGBF(255, 215, 0);
    FillEllipse(hdc, o.p.x, o.p.y, o.r, o.r, c);
    StrokeEllipse(hdc, o.p.x, o.p.y, o.r, o.r, RGBF(255, 255, 255), 1);
}

static void DrawPlanet(HDC hdc) {
    float x = G.planet.x;
    float y = G.planet.y;
    if (G.shake > 0) { x += rnd(-G.shake, G.shake); y += rnd(-G.shake, G.shake); }
    FillEllipse(hdc, x, y, 132, 132, RGBF(245, 166, 95));
    FillEllipse(hdc, x, y - 30, 110, 64, RGBF(255, 90, 170));
    FillEllipse(hdc, x, y, 52, 52, RGBF(16, 7, 31));
    FillEllipse(hdc, x - 42, y - 28, 13, 13, RGBF(255, 255, 255));
    FillEllipse(hdc, x + 42, y - 28, 13, 13, RGBF(255, 255, 255));
    FillEllipse(hdc, x - 38, y - 28, 5, 5, RGBF(0, 0, 0));
    FillEllipse(hdc, x + 46, y - 28, 5, 5, RGBF(0, 0, 0));
    FillEllipse(hdc, x, y - 102, 36, 20, RGBF(70, 0, 35));
    if (G.shield > 0) StrokeEllipse(hdc, x, y, 150, 150, RGBF(120, 230, 255), 5);
}

static void Render(HDC hdc, int ww, int wh) {
    HDC mem = CreateCompatibleDC(hdc);
    HBITMAP bmp = CreateCompatibleBitmap(hdc, ww, wh);
    HGDIOBJ oldBmp = SelectObject(mem, bmp);

    HBRUSH bg = CreateSolidBrush(RGBF(16, 7, 31));
    RECT rc = {0, 0, ww, wh};
    FillRect(mem, &rc, bg);
    DeleteObject(bg);

    float sx = (float)ww / VIEW_W;
    float sy = (float)wh / VIEW_H;
    float s = min(sx, sy);
    int ox = (int)((ww - VIEW_W * s) * 0.5f);
    int oy = (int)((wh - VIEW_H * s) * 0.5f);
    SetGraphicsMode(mem, GM_ADVANCED);
    XFORM xf = {s, 0, 0, s, (FLOAT)ox, (FLOAT)oy};
    SetWorldTransform(mem, &xf);

    for (int i = 0; i < 100; ++i) {
        int x = (i * 127) % 1280;
        int y = (i * 263) % 720;
        FillEllipse(mem, (float)x, (float)y, 1.5f, 1.5f, RGBF(180, 180, 220));
    }

    if (mouseAttract || mouseRepel) StrokeEllipse(mem, mouse.x, mouse.y, mouseAttract ? 145 : 170, mouseAttract ? 145 : 170, mouseAttract ? RGBF(255, 120, 190) : RGBF(120, 200, 255), 4);
    if (G.beacon > 0) StrokeEllipse(mem, G.planet.x, G.planet.y, 260, 260, RGBF(255, 215, 0), 3);

    for (const Obj& o : G.objects) DrawObject(mem, o);

    if (G.boss.active) {
        COLORREF c = G.boss.type == 1 ? RGBF(255, 48, 72) : G.boss.type == 2 ? RGBF(112, 64, 30) : RGBF(204, 130, 32);
        FillEllipse(mem, G.boss.p.x, G.boss.p.y, 55 + 12 * G.boss.type, 55 + 12 * G.boss.type, c);
        RECT bar = {390, 74, 890, 92};
        HBRUSH back = CreateSolidBrush(RGBF(50, 0, 0)); FillRect(mem, &bar, back); DeleteObject(back);
        RECT hp = {390, 74, 390 + (int)(500 * (G.boss.hp / G.boss.maxHp)), 92};
        HBRUSH hpB = CreateSolidBrush(RGBF(255, 50, 70)); FillRect(mem, &hp, hpB); DeleteObject(hpB);
    }

    DrawPlanet(mem);

    for (const Particle& p : G.particles) FillEllipse(mem, p.p.x, p.p.y, p.r, p.r, p.color);

    DrawTextAt(mem, 20, 14, L"Score: " + std::to_wstring(G.score), 30, RGBF(255, 220, 40));
    DrawTextAt(mem, 520, 14, L"Level " + std::to_wstring(G.level) + L" Wave " + std::to_wstring(G.wave) + L"/10", 26, RGBF(255, 255, 255));
    DrawTextAt(mem, 1050, 14, L"Time: " + std::to_wstring((int)max(0.0f, G.waveTime)), 26, RGBF(255, 255, 255));
    if (G.combo > 0) DrawTextAt(mem, 20, 54, L"COMBO x" + std::to_wstring(min(8, 1 + G.combo)), 34, RGBF(255, 110, 210));
    if (G.messageTimer > 0) DrawTextAt(mem, 190, 138, G.message, 48, RGBF(255, 226, 80), true);
    DrawTextAt(mem, 20, 690, L"WASD: tilt planet | Mouse: magnet | LMB: attract | RMB: repel | R: restart", 18, RGBF(220, 220, 220));

    ModifyWorldTransform(mem, nullptr, MWT_IDENTITY);
    BitBlt(hdc, 0, 0, ww, wh, mem, 0, 0, SRCCOPY);
    SelectObject(mem, oldBmp);
    DeleteObject(bmp);
    DeleteDC(mem);
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        SetTimer(hwnd, 1, 16, nullptr);
        return 0;
    case WM_TIMER: {
        LARGE_INTEGER now;
        QueryPerformanceCounter(&now);
        float dt = (float)(now.QuadPart - lastCounter.QuadPart) / (float)freq.QuadPart;
        lastCounter = now;
        dt = min(dt, 0.033f);
        Update(dt);
        InvalidateRect(hwnd, nullptr, FALSE);
        return 0;
    }
    case WM_KEYDOWN:
        if (wParam < 256) keyState[wParam] = true;
        if (wParam == 'R') ResetGame();
        if (wParam == VK_ESCAPE) PostQuitMessage(0);
        return 0;
    case WM_KEYUP:
        if (wParam < 256) keyState[wParam] = false;
        return 0;
    case WM_MOUSEMOVE: {
        RECT rc;
        GetClientRect(hwnd, &rc);
        float sx = (float)(rc.right - rc.left) / VIEW_W;
        float sy = (float)(rc.bottom - rc.top) / VIEW_H;
        float s = min(sx, sy);
        float ox = ((rc.right - rc.left) - VIEW_W * s) * 0.5f;
        float oy = ((rc.bottom - rc.top) - VIEW_H * s) * 0.5f;
        mouse.x = ((float)GET_X_LPARAM(lParam) - ox) / s;
        mouse.y = ((float)GET_Y_LPARAM(lParam) - oy) / s;
        return 0;
    }
    case WM_LBUTTONDOWN: mouseAttract = true; SetCapture(hwnd); return 0;
    case WM_LBUTTONUP: mouseAttract = false; ReleaseCapture(); return 0;
    case WM_RBUTTONDOWN: mouseRepel = true; SetCapture(hwnd); return 0;
    case WM_RBUTTONUP: mouseRepel = false; ReleaseCapture(); return 0;
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        RECT rc;
        GetClientRect(hwnd, &rc);
        Render(hdc, rc.right - rc.left, rc.bottom - rc.top);
        EndPaint(hwnd, &ps);
        return 0;
    }
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nCmdShow) {
    srand((unsigned)time(nullptr));
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&lastCounter);
    ResetGame();

    WNDCLASSW wc = {};
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.lpszClassName = L"EdiblePlanetWindow";
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hIcon = LoadIcon(nullptr, IDI_APPLICATION);
    RegisterClassW(&wc);

    g_hwnd = CreateWindowExW(0, wc.lpszClassName, L"Edible Planet: Cosmic Feast", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 1300, 760, nullptr, nullptr, hInst, nullptr);
    if (!g_hwnd) return 1;
    ShowWindow(g_hwnd, nCmdShow);
    UpdateWindow(g_hwnd);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return 0;
}
