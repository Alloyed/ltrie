#include <string.h>
#include "lua.h"
#include "lauxlib.h"

#define LMAX 64

#define lmod(s,size) ((int)(s) & ((size)-1))

#define hashpow2(n) (lmod((n), LMAX))
#define hashstr(s) ()
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


static int l_hashcode(lua_State* L)
{
	int n;
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
			n = -1; // FIXME
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
