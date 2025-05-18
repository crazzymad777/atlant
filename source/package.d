module atlant;

import atlant.utils.string;
import atlant.http.session;
import atlant.cache.gem;

import atlant.cache.hash_table;
HashTable ht;

void handleRequest(Request req, Response* res)
{
    import atlant.utils.data;
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

	snprintf(cast(char*) res.text, 256, "Requested Resource /%s Not Found", s2.data);
	res.type = Response.ResultType.text;
	res.status = 404;
	s2.drop();
	return;
}
