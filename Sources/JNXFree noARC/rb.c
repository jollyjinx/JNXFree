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

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rb.h"

/* Creates and returns a new table
   with comparison function |compare| using parameter |param|
   and memory allocator |allocator|.
   Returns |NULL| if memory allocation failed. */
struct bprb_table *
bprb_create (bprb_comparison_func *compare, void *param,
            struct libavl_allocator *allocator)
{
  struct bprb_table *tree;

  assert (compare != NULL);

  if (allocator == NULL)
    allocator = &bprb_allocator_default;

  tree = allocator->libavl_malloc (allocator, sizeof *tree);
  if (tree == NULL)
    return NULL;

  tree->bprb_root = NULL;
  tree->bprb_compare = compare;
  tree->bprb_param = param;
  tree->bprb_alloc = allocator;
  tree->bprb_count = 0;
  tree->bprb_generation = 0;

  return tree;
}

/* Search |tree| for an item matching |item|, and return it if found.
   Otherwise return |NULL|. */
void *
bprb_find (const struct bprb_table *tree, const void *item)
{
  const struct bprb_node *p;

  assert (tree != NULL && item != NULL);
  for (p = tree->bprb_root; p != NULL; )
    {
      int cmp = tree->bprb_compare (item, p->bprb_data, tree->bprb_param);

      if (cmp < 0)
        p = p->bprb_link[0];
      else if (cmp > 0)
        p = p->bprb_link[1];
      else /* |cmp == 0| */
        return p->bprb_data;
    }

  return NULL;
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
void **
bprb_probe (struct bprb_table *tree, void *item)
{
  struct bprb_node *pa[RB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                             /* Stack height. */

  struct bprb_node *p; /* Traverses tree looking for insertion point. */
  struct bprb_node *n; /* Newly inserted node. */

  assert (tree != NULL && item != NULL);

  pa[0] = (struct bprb_node *) &tree->bprb_root;
  da[0] = 0;
  k = 1;
  for (p = tree->bprb_root; p != NULL; p = p->bprb_link[da[k - 1]])
    {
      int cmp = tree->bprb_compare (item, p->bprb_data, tree->bprb_param);
      if (cmp == 0)
        return &p->bprb_data;

      pa[k] = p;
      da[k++] = cmp > 0;
    }

  n = pa[k - 1]->bprb_link[da[k - 1]] =
    tree->bprb_alloc->libavl_malloc (tree->bprb_alloc, sizeof *n);
  if (n == NULL)
    return NULL;

  n->bprb_data = item;
  n->bprb_link[0] = n->bprb_link[1] = NULL;
  n->bprb_color = RB_RED;
  tree->bprb_count++;
  tree->bprb_generation++;

  while (k >= 3 && pa[k - 1]->bprb_color == RB_RED)
    {
      if (da[k - 2] == 0)
        {
          struct bprb_node *y = pa[k - 2]->bprb_link[1];
          if (y != NULL && y->bprb_color == RB_RED)
            {
              pa[k - 1]->bprb_color = y->bprb_color = RB_BLACK;
              pa[k - 2]->bprb_color = RB_RED;
              k -= 2;
            }
          else
            {
              struct bprb_node *x;

              if (da[k - 1] == 0)
                y = pa[k - 1];
              else
                {
                  x = pa[k - 1];
                  y = x->bprb_link[1];
                  x->bprb_link[1] = y->bprb_link[0];
                  y->bprb_link[0] = x;
                  pa[k - 2]->bprb_link[0] = y;
                }

              x = pa[k - 2];
              x->bprb_color = RB_RED;
              y->bprb_color = RB_BLACK;

              x->bprb_link[0] = y->bprb_link[1];
              y->bprb_link[1] = x;
              pa[k - 3]->bprb_link[da[k - 3]] = y;
              break;
            }
        }
      else
        {
          struct bprb_node *y = pa[k - 2]->bprb_link[0];
          if (y != NULL && y->bprb_color == RB_RED)
            {
              pa[k - 1]->bprb_color = y->bprb_color = RB_BLACK;
              pa[k - 2]->bprb_color = RB_RED;
              k -= 2;
            }
          else
            {
              struct bprb_node *x;

              if (da[k - 1] == 1)
                y = pa[k - 1];
              else
                {
                  x = pa[k - 1];
                  y = x->bprb_link[0];
                  x->bprb_link[0] = y->bprb_link[1];
                  y->bprb_link[1] = x;
                  pa[k - 2]->bprb_link[1] = y;
                }

              x = pa[k - 2];
              x->bprb_color = RB_RED;
              y->bprb_color = RB_BLACK;

              x->bprb_link[1] = y->bprb_link[0];
              y->bprb_link[0] = x;
              pa[k - 3]->bprb_link[da[k - 3]] = y;
              break;
            }
        }
    }
  tree->bprb_root->bprb_color = RB_BLACK;


  return &n->bprb_data;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
void *
bprb_insert (struct bprb_table *table, void *item)
{
  void **p = bprb_probe (table, item);
  return p == NULL || *p == item ? NULL : *p;
}

/* Inserts |item| into |table|, replacing any duplicate item.
   Returns |NULL| if |item| was inserted without replacing a duplicate,
   or if a memory allocation error occurred.
   Otherwise, returns the item that was replaced. */
void *
bprb_replace (struct bprb_table *table, void *item)
{
  void **p = bprb_probe (table, item);
  if (p == NULL || *p == item)
    return NULL;
  else
    {
      void *r = *p;
      *p = item;
      return r;
    }
}

/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
void *
bprb_delete (struct bprb_table *tree, const void *item)
{
  struct bprb_node *pa[RB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                             /* Stack height. */

  struct bprb_node *p;    /* The node to delete, or a node part way to it. */
  int cmp;              /* Result of comparison between |item| and |p|. */

  assert (tree != NULL && item != NULL);

  k = 0;
  p = (struct bprb_node *) &tree->bprb_root;
  for (cmp = -1; cmp != 0;
       cmp = tree->bprb_compare (item, p->bprb_data, tree->bprb_param))
    {
      int dir = cmp > 0;

      pa[k] = p;
      da[k++] = dir;

      p = p->bprb_link[dir];
      if (p == NULL)
        return NULL;
    }
  item = p->bprb_data;

  if (p->bprb_link[1] == NULL)
    pa[k - 1]->bprb_link[da[k - 1]] = p->bprb_link[0];
  else
    {
      enum bprb_color t;
      struct bprb_node *r = p->bprb_link[1];

      if (r->bprb_link[0] == NULL)
        {
          r->bprb_link[0] = p->bprb_link[0];
          t = r->bprb_color;
          r->bprb_color = p->bprb_color;
          p->bprb_color = t;
          pa[k - 1]->bprb_link[da[k - 1]] = r;
          da[k] = 1;
          pa[k++] = r;
        }
      else
        {
          struct bprb_node *s;
          int j = k++;

          for (;;)
            {
              da[k] = 0;
              pa[k++] = r;
              s = r->bprb_link[0];
              if (s->bprb_link[0] == NULL)
                break;

              r = s;
            }

          da[j] = 1;
          pa[j] = s;
          pa[j - 1]->bprb_link[da[j - 1]] = s;

          s->bprb_link[0] = p->bprb_link[0];
          r->bprb_link[0] = s->bprb_link[1];
          s->bprb_link[1] = p->bprb_link[1];

          t = s->bprb_color;
          s->bprb_color = p->bprb_color;
          p->bprb_color = t;
        }
    }

  if (p->bprb_color == RB_BLACK)
    {
      for (;;)
        {
          struct bprb_node *x = pa[k - 1]->bprb_link[da[k - 1]];
          if (x != NULL && x->bprb_color == RB_RED)
            {
              x->bprb_color = RB_BLACK;
              break;
            }
          if (k < 2)
            break;

          if (da[k - 1] == 0)
            {
              struct bprb_node *w = pa[k - 1]->bprb_link[1];

              if (w->bprb_color == RB_RED)
                {
                  w->bprb_color = RB_BLACK;
                  pa[k - 1]->bprb_color = RB_RED;

                  pa[k - 1]->bprb_link[1] = w->bprb_link[0];
                  w->bprb_link[0] = pa[k - 1];
                  pa[k - 2]->bprb_link[da[k - 2]] = w;

                  pa[k] = pa[k - 1];
                  da[k] = 0;
                  pa[k - 1] = w;
                  k++;

                  w = pa[k - 1]->bprb_link[1];
                }

              if ((w->bprb_link[0] == NULL
                   || w->bprb_link[0]->bprb_color == RB_BLACK)
                  && (w->bprb_link[1] == NULL
                      || w->bprb_link[1]->bprb_color == RB_BLACK))
                w->bprb_color = RB_RED;
              else
                {
                  if (w->bprb_link[1] == NULL
                      || w->bprb_link[1]->bprb_color == RB_BLACK)
                    {
                      struct bprb_node *y = w->bprb_link[0];
                      y->bprb_color = RB_BLACK;
                      w->bprb_color = RB_RED;
                      w->bprb_link[0] = y->bprb_link[1];
                      y->bprb_link[1] = w;
                      w = pa[k - 1]->bprb_link[1] = y;
                    }

                  w->bprb_color = pa[k - 1]->bprb_color;
                  pa[k - 1]->bprb_color = RB_BLACK;
                  w->bprb_link[1]->bprb_color = RB_BLACK;

                  pa[k - 1]->bprb_link[1] = w->bprb_link[0];
                  w->bprb_link[0] = pa[k - 1];
                  pa[k - 2]->bprb_link[da[k - 2]] = w;
                  break;
                }
            }
          else
            {
              struct bprb_node *w = pa[k - 1]->bprb_link[0];

              if (w->bprb_color == RB_RED)
                {
                  w->bprb_color = RB_BLACK;
                  pa[k - 1]->bprb_color = RB_RED;

                  pa[k - 1]->bprb_link[0] = w->bprb_link[1];
                  w->bprb_link[1] = pa[k - 1];
                  pa[k - 2]->bprb_link[da[k - 2]] = w;

                  pa[k] = pa[k - 1];
                  da[k] = 1;
                  pa[k - 1] = w;
                  k++;

                  w = pa[k - 1]->bprb_link[0];
                }

              if ((w->bprb_link[0] == NULL
                   || w->bprb_link[0]->bprb_color == RB_BLACK)
                  && (w->bprb_link[1] == NULL
                      || w->bprb_link[1]->bprb_color == RB_BLACK))
                w->bprb_color = RB_RED;
              else
                {
                  if (w->bprb_link[0] == NULL
                      || w->bprb_link[0]->bprb_color == RB_BLACK)
                    {
                      struct bprb_node *y = w->bprb_link[1];
                      y->bprb_color = RB_BLACK;
                      w->bprb_color = RB_RED;
                      w->bprb_link[1] = y->bprb_link[0];
                      y->bprb_link[0] = w;
                      w = pa[k - 1]->bprb_link[0] = y;
                    }

                  w->bprb_color = pa[k - 1]->bprb_color;
                  pa[k - 1]->bprb_color = RB_BLACK;
                  w->bprb_link[0]->bprb_color = RB_BLACK;

                  pa[k - 1]->bprb_link[0] = w->bprb_link[1];
                  w->bprb_link[1] = pa[k - 1];
                  pa[k - 2]->bprb_link[da[k - 2]] = w;
                  break;
                }
            }

          k--;
        }

    }

  tree->bprb_alloc->libavl_free (tree->bprb_alloc, p);
  tree->bprb_count--;
  tree->bprb_generation++;
  return (void *) item;
}

/* Refreshes the stack of parent pointers in |trav|
   and updates its generation number. */
static void
trav_refresh (struct bprb_traverser *trav)
{
  assert (trav != NULL);

  trav->bprb_generation = trav->bprb_table->bprb_generation;

  if (trav->bprb_node != NULL)
    {
      bprb_comparison_func *cmp = trav->bprb_table->bprb_compare;
      void *param = trav->bprb_table->bprb_param;
      struct bprb_node *node = trav->bprb_node;
      struct bprb_node *i;

      trav->bprb_height = 0;
      for (i = trav->bprb_table->bprb_root; i != node; )
        {
          assert (trav->bprb_height < RB_MAX_HEIGHT);
          assert (i != NULL);

          trav->bprb_stack[trav->bprb_height++] = i;
          i = i->bprb_link[cmp (node->bprb_data, i->bprb_data, param) > 0];
        }
    }
}

/* Initializes |trav| for use with |tree|
   and selects the null node. */
void
bprb_t_init (struct bprb_traverser *trav, struct bprb_table *tree)
{
  trav->bprb_table = tree;
  trav->bprb_node = NULL;
  trav->bprb_height = 0;
  trav->bprb_generation = tree->bprb_generation;
}

/* Initializes |trav| for |tree|
   and selects and returns a pointer to its least-valued item.
   Returns |NULL| if |tree| contains no nodes. */
void *
bprb_t_first (struct bprb_traverser *trav, struct bprb_table *tree)
{
  struct bprb_node *x;

  assert (tree != NULL && trav != NULL);

  trav->bprb_table = tree;
  trav->bprb_height = 0;
  trav->bprb_generation = tree->bprb_generation;

  x = tree->bprb_root;
  if (x != NULL)
    while (x->bprb_link[0] != NULL)
      {
        assert (trav->bprb_height < RB_MAX_HEIGHT);
        trav->bprb_stack[trav->bprb_height++] = x;
        x = x->bprb_link[0];
      }
  trav->bprb_node = x;

  return x != NULL ? x->bprb_data : NULL;
}

/* Initializes |trav| for |tree|
   and selects and returns a pointer to its greatest-valued item.
   Returns |NULL| if |tree| contains no nodes. */
void *
bprb_t_last (struct bprb_traverser *trav, struct bprb_table *tree)
{
  struct bprb_node *x;

  assert (tree != NULL && trav != NULL);

  trav->bprb_table = tree;
  trav->bprb_height = 0;
  trav->bprb_generation = tree->bprb_generation;

  x = tree->bprb_root;
  if (x != NULL)
    while (x->bprb_link[1] != NULL)
      {
        assert (trav->bprb_height < RB_MAX_HEIGHT);
        trav->bprb_stack[trav->bprb_height++] = x;
        x = x->bprb_link[1];
      }
  trav->bprb_node = x;

  return x != NULL ? x->bprb_data : NULL;
}

/* Searches for |item| in |tree|.
   If found, initializes |trav| to the item found and returns the item
   as well.
   If there is no matching item, initializes |trav| to the null item
   and returns |NULL|. */
void *
bprb_t_find (struct bprb_traverser *trav, struct bprb_table *tree, void *item)
{
  struct bprb_node *p, *q;

  assert (trav != NULL && tree != NULL && item != NULL);
  trav->bprb_table = tree;
  trav->bprb_height = 0;
  trav->bprb_generation = tree->bprb_generation;
  for (p = tree->bprb_root; p != NULL; p = q)
    {
      int cmp = tree->bprb_compare (item, p->bprb_data, tree->bprb_param);

      if (cmp < 0)
        q = p->bprb_link[0];
      else if (cmp > 0)
        q = p->bprb_link[1];
      else /* |cmp == 0| */
        {
          trav->bprb_node = p;
          return p->bprb_data;
        }

      assert (trav->bprb_height < RB_MAX_HEIGHT);
      trav->bprb_stack[trav->bprb_height++] = p;
    }

  trav->bprb_height = 0;
  trav->bprb_node = NULL;
  return NULL;
}

/* Attempts to insert |item| into |tree|.
   If |item| is inserted successfully, it is returned and |trav| is
   initialized to its location.
   If a duplicate is found, it is returned and |trav| is initialized to
   its location.  No replacement of the item occurs.
   If a memory allocation failure occurs, |NULL| is returned and |trav|
   is initialized to the null item. */
void *
bprb_t_insert (struct bprb_traverser *trav, struct bprb_table *tree, void *item)
{
  void **p;

  assert (trav != NULL && tree != NULL && item != NULL);

  p = bprb_probe (tree, item);
  if (p != NULL)
    {
      trav->bprb_table = tree;
      trav->bprb_node =
        ((struct bprb_node *)
         ((char *) p - offsetof (struct bprb_node, bprb_data)));
      trav->bprb_generation = tree->bprb_generation - 1;
      return *p;
    }
  else
    {
      bprb_t_init (trav, tree);
      return NULL;
    }
}

/* Initializes |trav| to have the same current node as |src|. */
void *
bprb_t_copy (struct bprb_traverser *trav, const struct bprb_traverser *src)
{
  assert (trav != NULL && src != NULL);

  if (trav != src)
    {
      trav->bprb_table = src->bprb_table;
      trav->bprb_node = src->bprb_node;
      trav->bprb_generation = src->bprb_generation;
      if (trav->bprb_generation == trav->bprb_table->bprb_generation)
        {
          trav->bprb_height = src->bprb_height;
          memcpy (trav->bprb_stack, (const void *) src->bprb_stack,
                  sizeof *trav->bprb_stack * trav->bprb_height);
        }
    }

  return trav->bprb_node != NULL ? trav->bprb_node->bprb_data : NULL;
}

/* Returns the next data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
bprb_t_next (struct bprb_traverser *trav)
{
  struct bprb_node *x;

  assert (trav != NULL);

  if (trav->bprb_generation != trav->bprb_table->bprb_generation)
    trav_refresh (trav);

  x = trav->bprb_node;
  if (x == NULL)
    {
      return bprb_t_first (trav, trav->bprb_table);
    }
  else if (x->bprb_link[1] != NULL)
    {
      assert (trav->bprb_height < RB_MAX_HEIGHT);
      trav->bprb_stack[trav->bprb_height++] = x;
      x = x->bprb_link[1];

      while (x->bprb_link[0] != NULL)
        {
          assert (trav->bprb_height < RB_MAX_HEIGHT);
          trav->bprb_stack[trav->bprb_height++] = x;
          x = x->bprb_link[0];
        }
    }
  else
    {
      struct bprb_node *y;

      do
        {
          if (trav->bprb_height == 0)
            {
              trav->bprb_node = NULL;
              return NULL;
            }

          y = x;
          x = trav->bprb_stack[--trav->bprb_height];
        }
      while (y == x->bprb_link[1]);
    }
  trav->bprb_node = x;

  return x->bprb_data;
}

/* Returns the previous data item in inorder
   within the tree being traversed with |trav|,
   or if there are no more data items returns |NULL|. */
void *
bprb_t_prev (struct bprb_traverser *trav)
{
  struct bprb_node *x;

  assert (trav != NULL);

  if (trav->bprb_generation != trav->bprb_table->bprb_generation)
    trav_refresh (trav);

  x = trav->bprb_node;
  if (x == NULL)
    {
      return bprb_t_last (trav, trav->bprb_table);
    }
  else if (x->bprb_link[0] != NULL)
    {
      assert (trav->bprb_height < RB_MAX_HEIGHT);
      trav->bprb_stack[trav->bprb_height++] = x;
      x = x->bprb_link[0];

      while (x->bprb_link[1] != NULL)
        {
          assert (trav->bprb_height < RB_MAX_HEIGHT);
          trav->bprb_stack[trav->bprb_height++] = x;
          x = x->bprb_link[1];
        }
    }
  else
    {
      struct bprb_node *y;

      do
        {
          if (trav->bprb_height == 0)
            {
              trav->bprb_node = NULL;
              return NULL;
            }

          y = x;
          x = trav->bprb_stack[--trav->bprb_height];
        }
      while (y == x->bprb_link[0]);
    }
  trav->bprb_node = x;

  return x->bprb_data;
}

/* Returns |trav|'s current item. */
void *
bprb_t_cur (struct bprb_traverser *trav)
{
  assert (trav != NULL);

  return trav->bprb_node != NULL ? trav->bprb_node->bprb_data : NULL;
}

/* Replaces the current item in |trav| by |new| and returns the item replaced.
   |trav| must not have the null item selected.
   The new item must not upset the ordering of the tree. */
void *
bprb_t_replace (struct bprb_traverser *trav, void *new)
{
  void *old;

  assert (trav != NULL && trav->bprb_node != NULL && new != NULL);
  old = trav->bprb_node->bprb_data;
  trav->bprb_node->bprb_data = new;
  return old;
}

/* Destroys |new| with |bprb_destroy (new, destroy)|,
   first setting right links of nodes in |stack| within |new|
   to null pointers to avoid touching uninitialized data. */
static void
copy_error_recovery (struct bprb_node **stack, int height,
                     struct bprb_table *new, bprb_item_func *destroy)
{
  assert (stack != NULL && height >= 0 && new != NULL);

  for (; height > 2; height -= 2)
    stack[height - 1]->bprb_link[1] = NULL;
  bprb_destroy (new, destroy);
}

/* Copies |org| to a newly created tree, which is returned.
   If |copy != NULL|, each data item in |org| is first passed to |copy|,
   and the return values are inserted into the tree,
   with |NULL| return values taken as indications of failure.
   On failure, destroys the partially created new tree,
   applying |destroy|, if non-null, to each item in the new tree so far,
   and returns |NULL|.
   If |allocator != NULL|, it is used for allocation in the new tree.
   Otherwise, the same allocator used for |org| is used. */
struct bprb_table *
bprb_copy (const struct bprb_table *org, bprb_copy_func *copy,
          bprb_item_func *destroy, struct libavl_allocator *allocator)
{
  struct bprb_node *stack[2 * (RB_MAX_HEIGHT + 1)];
  int height = 0;

  struct bprb_table *new;
  const struct bprb_node *x;
  struct bprb_node *y;

  assert (org != NULL);
  new = bprb_create (org->bprb_compare, org->bprb_param,
                    allocator != NULL ? allocator : org->bprb_alloc);
  if (new == NULL)
    return NULL;
  new->bprb_count = org->bprb_count;
  if (new->bprb_count == 0)
    return new;

  x = (const struct bprb_node *) &org->bprb_root;
  y = (struct bprb_node *) &new->bprb_root;
  for (;;)
    {
      while (x->bprb_link[0] != NULL)
        {
          assert (height < 2 * (RB_MAX_HEIGHT + 1));

          y->bprb_link[0] =
            new->bprb_alloc->libavl_malloc (new->bprb_alloc,
                                           sizeof *y->bprb_link[0]);
          if (y->bprb_link[0] == NULL)
            {
              if (y != (struct bprb_node *) &new->bprb_root)
                {
                  y->bprb_data = NULL;
                  y->bprb_link[1] = NULL;
                }

              copy_error_recovery (stack, height, new, destroy);
              return NULL;
            }

          stack[height++] = (struct bprb_node *) x;
          stack[height++] = y;
          x = x->bprb_link[0];
          y = y->bprb_link[0];
        }
      y->bprb_link[0] = NULL;

      for (;;)
        {
          y->bprb_color = x->bprb_color;
          if (copy == NULL)
            y->bprb_data = x->bprb_data;
          else
            {
              y->bprb_data = copy (x->bprb_data, org->bprb_param);
              if (y->bprb_data == NULL)
                {
                  y->bprb_link[1] = NULL;
                  copy_error_recovery (stack, height, new, destroy);
                  return NULL;
                }
            }

          if (x->bprb_link[1] != NULL)
            {
              y->bprb_link[1] =
                new->bprb_alloc->libavl_malloc (new->bprb_alloc,
                                               sizeof *y->bprb_link[1]);
              if (y->bprb_link[1] == NULL)
                {
                  copy_error_recovery (stack, height, new, destroy);
                  return NULL;
                }

              x = x->bprb_link[1];
              y = y->bprb_link[1];
              break;
            }
          else
            y->bprb_link[1] = NULL;

          if (height <= 2)
            return new;

          y = stack[--height];
          x = stack[--height];
        }
    }
}

/* Frees storage allocated for |tree|.
   If |destroy != NULL|, applies it to each data item in inorder. */
void
bprb_destroy (struct bprb_table *tree, bprb_item_func *destroy)
{
  struct bprb_node *p, *q;

  assert (tree != NULL);

  for (p = tree->bprb_root; p != NULL; p = q)
    if (p->bprb_link[0] == NULL)
      {
        q = p->bprb_link[1];
        if (destroy != NULL && p->bprb_data != NULL)
          destroy (p->bprb_data, tree->bprb_param);
        tree->bprb_alloc->libavl_free (tree->bprb_alloc, p);
      }
    else
      {
        q = p->bprb_link[0];
        p->bprb_link[0] = q->bprb_link[1];
        q->bprb_link[1] = p;
      }

  tree->bprb_alloc->libavl_free (tree->bprb_alloc, tree);
}

/* Allocates |size| bytes of space using |malloc()|.
   Returns a null pointer if allocation fails. */
void *
bprb_malloc (struct libavl_allocator *allocator, size_t size)
{
  assert (allocator != NULL && size > 0);
  return malloc (size);
}

/* Frees |block|. */
void
bprb_free (struct libavl_allocator *allocator, void *block)
{
  assert (allocator != NULL && block != NULL);
  free (block);
}

/* Default memory allocator that uses |malloc()| and |free()|. */
struct libavl_allocator bprb_allocator_default =
  {
    bprb_malloc,
    bprb_free
  };

#undef NDEBUG
#include <assert.h>

/* Asserts that |bprb_insert()| succeeds at inserting |item| into |table|. */
void
(bprb_assert_insert) (struct bprb_table *table, void *item)
{
  void **p = bprb_probe (table, item);
  assert (p != NULL && *p == item);
}

/* Asserts that |bprb_delete()| really removes |item| from |table|,
   and returns the removed item. */
void *
(bprb_assert_delete) (struct bprb_table *table, void *item)
{
  void *p = bprb_delete (table, item);
  assert (p != NULL);
  return p;
}

