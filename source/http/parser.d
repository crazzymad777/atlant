module atlant.http.parser;

import atlant.http.session;
import atlant.http.chunk;

import std.container : DList;

enum HeaderField
{
    UNKNOWN,
    CONNECTION
}

struct Request
{
    HttpMethod method;
    string path;
    bool keepAlive;
}

struct Parser
{
    private enum Item
    {
        Method,
        Path,
        HttpVersion,
        Header,
        HeaderSemicolon,
        HeaderValue
    }

    DList!Request requests;
    int index;
    char[1024] memory;
    private Item item = Item.Method;
    private Request current;
    private HeaderField header;

    int feed(Chunk* chunk)
    {
        int count = 0;
        for (int i = 0; i < chunk.length; i++)
        {
            if (chunk.buffer[i] == '\n')
            {
                if (index > 0)
                {
                    if (memory[index-1] == '\r')
                    {
                        if (item == Item.Header)
                        {
                            item = Item.Method;
                            // import core.stdc.stdio;
                            // if (current.method == HttpMethod.GET) printf("GET");
                            // else if (current.method == HttpMethod.HEAD) printf("HEAD");
                            // else printf("OTHERWISE");
                            //
                            // printf(" %s\n", current.path.ptr);

                            requests.insertBack(current);
                            current = Request();
                            count++;
                        }
                        else
                        {
                            if (header == HeaderField.CONNECTION)
                            {
                                import core.stdc.string;
                                memory[index] = '\0';
                                if (strcmp(memory.ptr, "closed".ptr) == 0)
                                {
                                    current.keepAlive = false;
                                }
                                else if (strcmp(memory.ptr, "keep-alive".ptr) == 0)
                                {
                                    current.keepAlive = true;
                                }
                            }
                            header = HeaderField.UNKNOWN;
                            item = Item.Header;
                        }
                        index = 0;
                    }
                }
            }
            else if (chunk.buffer[i] == ':')
            {
                import core.stdc.string;
                memory[index] = '\0';
                if (strcmp(memory.ptr, "Connection".ptr) == 0)
                {
                    header = HeaderField.CONNECTION;
                }
                item = Item.HeaderSemicolon;
            }
            else if (chunk.buffer[i] == ' ')
            {
                if (item == Item.Method)
                {
                    import core.stdc.string;
                    item = Item.Path;
                    memory[index] = '\0';

                    if (strcmp(memory.ptr, "HEAD".ptr) == 0)
                    {
                        current.method = HttpMethod.HEAD;
                    }
                    else if (strcmp(memory.ptr, "GET".ptr) == 0)
                    {
                        current.method = HttpMethod.GET;
                    }
                    index = 0;
                }
                else if (item == Item.Path)
                {
                    memory[index] = '\0';
                    index++;
                    current.path = memory[0..index].dup;

                    item = Item.HttpVersion;
                    index = 0;
                }

                if (item == Item.HeaderSemicolon)
                {
                    item = Item.HeaderValue;
                    index = 0;
                }
            }
            else
            {
                memory[index] = chunk.buffer[i];
                index++;
            }
        }
        return count;
    }
}
