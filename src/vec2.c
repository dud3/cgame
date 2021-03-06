#include "vec2.h"

#include <stdio.h>

#include "saveload.h"

Vec2 vec2_zero = { 0.0, 0.0 };

Vec2 vec2_add(Vec2 u, Vec2 v)
{
    return vec2(u.x + v.x, u.y + v.y);
}
Vec2 vec2_sub(Vec2 u, Vec2 v)
{
    return vec2(u.x - v.x, u.y - v.y);
}
Vec2 vec2_mul(Vec2 u, Vec2 v)
{
    return vec2(u.x * v.x, u.y * v.y);
}
Vec2 vec2_div(Vec2 u, Vec2 v)
{
    return vec2(u.x / v.x, u.y / v.y);
}
Vec2 vec2_scalar_mul(Vec2 v, Scalar f)
{
    return vec2(v.x * f, v.y * f);
}
Vec2 vec2_scalar_div(Vec2 v, Scalar f)
{
    return vec2(v.x / f, v.y / f);
}
Vec2 scalar_vec2_div(Scalar f, Vec2 v)
{
    return vec2(f / v.x, f / v.y);
}
Vec2 vec2_neg(Vec2 v)
{
    return vec2(-v.x, -v.y);
}

Scalar vec2_len(Vec2 v)
{
    return scalar_sqrt(v.x * v.x + v.y * v.y);
}
Vec2 vec2_normalize(Vec2 v)
{
    if (v.x == 0 && v.y == 0)
        return v;
    return vec2_scalar_div(v, vec2_len(v));
}
Scalar vec2_dot(Vec2 u, Vec2 v)
{
    return u.x * v.x + u.y * v.y;
}
Scalar vec2_dist(Vec2 u, Vec2 v)
{
    return vec2_len(vec2_sub(u, v));
}

Vec2 vec2_rot(Vec2 v, Scalar rot)
{
    return vec2(v.x * scalar_cos(rot) - v.y * scalar_sin(rot),
                v.x * scalar_sin(rot) + v.y * scalar_cos(rot));
}
Scalar vec2_atan2(Vec2 v)
{
    return scalar_atan2(v.y, v.x);
}

void vec2_save(Vec2 *v, const char *n, Store *s)
{
    Store *t;

    if (store_child_save_compressed(&t, n, s))
    {
        scalar_save(&v->x, "x", t);
        scalar_save(&v->y, "y", t);
    }
}
bool vec2_load(Vec2 *v, const char *n, Vec2 d, Store *s)
{
    Store *t;

    if (store_child_load(&t, n, s))
    {
        scalar_load(&v->x, "x", 0, t);
        scalar_load(&v->y, "y", 0, t);
    }
    else
        *v = d;
    return t != NULL;
}

#undef vec2
Vec2 vec2(Scalar x, Scalar y)
{
    return (Vec2) { x, y };
}
