/*
 * A straight copy-paste of Lua's existing hashing capabilities, using Lua's
 * public API instead of the internal one. As of 2015/05/04 I have not tested
 * this for collisions, performance, etc. so it's probably totally suboptimal.
 * Sorry~
 * 
 * For the original sources, check ltable.c. An online link:
 *     http://www.lua.org/source/5.1/ltable.c.html
 *
 *  Copyright (c) 1994–2015 Lua.org, PUC-Rio.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *
 */

#include <string.h>
#include "lua.h"
#include "lauxlib.h"

#define LMAX 64

#define lmod(s,size) ((int)(s) & ((size)-1))

#define hashpow2(n) (lmod((n), LMAX))
#define hashbool(p) hashpow2(p)
#define hashmod(n) ((n) % ((LMAX - 1) | 1))
#define hashptr(p) hashmod(ptr2int(p))

#define numints ((int)sizeof(lua_Number)/sizeof(int))
static unsigned long ptr2int(const void* ptr)
{
	return (unsigned long) ptr;
}

static int hashnum(lua_Number n)
{
	unsigned int a[numints];
	int i;
	if (n == 0) { /* avoid problems with -0 */
		return 0;
	}
	memcpy(a, &n, sizeof(a));
	for (i = 1; i < numints; i++) {
		a[0] += a[i];
	}
	return hashmod(a[0]);
}

/*
 * This bit is taken from lstring, luaS_newlstr()
 */
static int hashstr(const char* str, size_t len)
{
	unsigned int h = (unsigned int) len;
	/* if string is too long, don't hash all its chars */
	size_t step = (len>>5) + 1; 
	size_t i;
	for (i = len; i >= step; i -= step) {
		h = h ^ ((h<<5) + (h>>2) + (unsigned char) str[i-1]);
	}
	return (int) h;
}

static int l_hashcode(lua_State* L)
{
	int n;
	const char* s;
	size_t len;
	int type = lua_type(L, 1);

	switch (type) {
		case LUA_TNUMBER:
			n = hashnum(lua_tonumber(L, 1));
			break;
		case LUA_TBOOLEAN:
			n = hashbool(lua_toboolean(L, 1));
			break;
		case LUA_TNIL:
			n = 0;
			break;
		case LUA_TSTRING:
			s = lua_tolstring(L, 1, &len);
			n = hashstr(s, len);
			break;
		default:
			n = hashptr(lua_topointer(L, 1));
			break;
	}

	lua_pushnumber(L, n);
	return 1;
}

/*
** Adapted from Lua 5.2.0, and then from compat-5.2
*/
void setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
	luaL_checkstack(L, nup+1, "too many upvalues");
	for (; l->name != NULL; l++) {  /* fill the table with given functions */
		int i;
		lua_pushstring(L, l->name);
		for (i = 0; i < nup; i++)  /* copy upvalues to the top */
			lua_pushvalue(L, -(nup + 1));
		lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
		/* table must be below the upvalues, the name and the closure */
		lua_settable(L, -(nup + 3));
	}
	lua_pop(L, nup);  /* remove upvalues */
}

static const struct luaL_Reg tbl [] = {
	{"hashcode", l_hashcode},
	{NULL, NULL}
};

int luaopen_hashcode(lua_State* L)
{
	lua_newtable(L);
	setfuncs(L, tbl, 0);
	return 1;
}
