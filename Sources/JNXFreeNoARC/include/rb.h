/* Produced by texiweb from libavl.w. */

/* libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
   02110-1301 USA.
*/

#ifndef RB_H
#define RB_H 1

#include <stddef.h>

/* Function types. */
typedef int bprb_comparison_func (const void *bprb_a, const void *bprb_b,
                                 void *bprb_param);
typedef void bprb_item_func (void *bprb_item, void *bprb_param);
typedef void *bprb_copy_func (void *bprb_item, void *bprb_param);

#ifndef LIBAVL_ALLOCATOR
#define LIBAVL_ALLOCATOR
/* Memory allocator. */
struct libavl_allocator
  {
    void *(*libavl_malloc) (struct libavl_allocator *, size_t libavl_size);
    void (*libavl_free) (struct libavl_allocator *, void *libavl_block);
  };
#endif

/* Default memory allocator. */
extern struct libavl_allocator bprb_allocator_default;
void *bprb_malloc (struct libavl_allocator *, size_t);
void bprb_free (struct libavl_allocator *, void *);

/* Maximum RB height. */
#ifndef RB_MAX_HEIGHT
#define RB_MAX_HEIGHT 128
#endif

/* Tree data structure. */
struct bprb_table
  {
    struct bprb_node *bprb_root;          /* Tree's root. */
    bprb_comparison_func *bprb_compare;   /* Comparison function. */
    void *bprb_param;                    /* Extra argument to |bprb_compare|. */
    struct libavl_allocator *bprb_alloc; /* Memory allocator. */
    size_t bprb_count;                   /* Number of items in tree. */
    unsigned long bprb_generation;       /* Generation number. */
  };

/* Color of a red-black node. */
enum bprb_color
  {
    RB_BLACK,   /* Black. */
    RB_RED      /* Red. */
  };

/* A red-black tree node. */
struct bprb_node
  {
    struct bprb_node *bprb_link[2];   /* Subtrees. */
    void *bprb_data;                /* Pointer to data. */
    unsigned char bprb_color;       /* Color. */
  };

/* RB traverser structure. */
struct bprb_traverser
  {
    struct bprb_table *bprb_table;        /* Tree being traversed. */
    struct bprb_node *bprb_node;          /* Current node in tree. */
    struct bprb_node *bprb_stack[RB_MAX_HEIGHT];
                                        /* All the nodes above |bprb_node|. */
    size_t bprb_height;                  /* Number of nodes in |bprb_parent|. */
    unsigned long bprb_generation;       /* Generation number. */
  };

/* Table functions. */
struct bprb_table *bprb_create (bprb_comparison_func *, void *,
                              struct libavl_allocator *);
struct bprb_table *bprb_copy (const struct bprb_table *, bprb_copy_func *,
                            bprb_item_func *, struct libavl_allocator *);
void bprb_destroy (struct bprb_table *, bprb_item_func *);
void **bprb_probe (struct bprb_table *, void *);
void *bprb_insert (struct bprb_table *, void *);
void *bprb_replace (struct bprb_table *, void *);
void *bprb_delete (struct bprb_table *, const void *);
void *bprb_find (const struct bprb_table *, const void *);
void bprb_assert_insert (struct bprb_table *, void *);
void *bprb_assert_delete (struct bprb_table *, void *);

#define bprb_count(table) ((size_t) (table)->bprb_count)

/* Table traverser functions. */
void bprb_t_init (struct bprb_traverser *, struct bprb_table *);
void *bprb_t_first (struct bprb_traverser *, struct bprb_table *);
void *bprb_t_last (struct bprb_traverser *, struct bprb_table *);
void *bprb_t_find (struct bprb_traverser *, struct bprb_table *, void *);
void *bprb_t_insert (struct bprb_traverser *, struct bprb_table *, void *);
void *bprb_t_copy (struct bprb_traverser *, const struct bprb_traverser *);
void *bprb_t_next (struct bprb_traverser *);
void *bprb_t_prev (struct bprb_traverser *);
void *bprb_t_cur (struct bprb_traverser *);
void *bprb_t_replace (struct bprb_traverser *, void *);

#endif /* rb.h */
