#ifndef EDIT_H
#define EDIT_H

#include <stdbool.h>

#include "entity.h"
#include "bbox.h"
#include "color.h"
#include "script_export.h"

SCRIPT(edit,

       EXPORT void edit_set_enabled(bool e);
       EXPORT bool edit_get_enabled();

       /* non-editable entities cannot be selected */
       EXPORT void edit_set_editable(Entity ent, bool editable);
       EXPORT bool edit_get_editable(Entity ent);

       /* non-negative on each dimension -- zero means no grid */
       EXPORT void edit_set_grid_size(Vec2 size);
       EXPORT Vec2 edit_get_grid_size();

       /* used for click selecting etc. */
       EXPORT void edit_bboxes_update(Entity ent, BBox bbox); /* merge bbox */
       EXPORT bool edit_bboxes_has(Entity ent);
       EXPORT BBox edit_bboxes_get(Entity ent);
       EXPORT unsigned int edit_bboxes_get_num();
       typedef struct EntityBBoxPair EntityBBoxPair;
       struct EntityBBoxPair { Entity ent; BBox bbox; };
       EXPORT EntityBBoxPair edit_bboxes_get_nth(unsigned int n);
       EXPORT void edit_bboxes_set_selected(Entity ent, bool selected);

       /* draw a line between two world-space coords */
       EXPORT void edit_line_add(Vec2 a, Vec2 b, Scalar point_size,
                                 Color color);

    )

void edit_clear();

void edit_init();
void edit_deinit();
void edit_update_all();
void edit_draw_all();
void edit_save_all(Store *s);
void edit_load_all(Store *s);

#endif
