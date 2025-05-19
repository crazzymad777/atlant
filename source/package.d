module atlant;

import atlant.utils.string;
import atlant.http.session;
import atlant.cache.gem;

import atlant.cache.hash_table;
HashTable ht;

void handleRequest(Request req, Response* res)
{
    import atlant.utils.array;
    import core.stdc.stdio;

    String s2;
    decodeURI(&req.s1, &s2);
	auto gem = ht.getGem(&s2);

	if (gem !is null)
	{
        *res = Response(200, Response.ResultType.gem, gem: gem);
        s2.drop();
        return;
	}

    string str = "Requested Resource /%s Not Found";
	size_t n = str.length - 2 + s2.length + 1;
	res.array = Array!(char)(n);
	res.type = Response.ResultType.array;
	snprintf(res.array.data(), n, str.ptr, s2.data);
	res.status = 404;
	s2.drop();
	return;
}
