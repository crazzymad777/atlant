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
    bool keepAlive;
    char* path;
}

struct Parser
{
    private enum Item
    {
        Method,
        Path,
        HttpVersion,
        Header,
        HeaderValue
    }

    DList!Request requests;
    int index = 0;
    char[1024] memory;
    private Item item = Item.Method;
    private Request current = Request();
    private HeaderField header;

    int feed(Chunk* chunk)
    {
        import core.stdc.ctype;
        int count = 0;
        for (int i = 0; i < chunk.length; i++)
        {
            bool reset = false;
            if (item == Item.Method)
            {
                if (chunk.buffer[i] == ' ')
                {
                    import core.stdc.string;
                    memory[index] = '\0';

                    if (strcmp(memory.ptr, "HEAD".ptr) == 0)
                    {
                        current.method = HttpMethod.HEAD;
                    }
                    else if (strcmp(memory.ptr, "GET".ptr) == 0)
                    {
                        current.method = HttpMethod.GET;
                    }

                    item = Item.Path;
                    reset = true;
                }
            }
            else if (item == Item.Path)
            {
                if (chunk.buffer[i] == ' ')
                {
                    import core.stdc.string;
                    memory[index] = '\0';
                    current.path = strdup(&memory[0]);
                    item = Item.HttpVersion;
                    reset = true;
                }
            }
            else if (item == Item.HttpVersion)
            {
                if (chunk.buffer[i] == '\n')
                {
                    if (index > 0 && memory[index-1] == '\r')
                    {
                        item = Item.Header;
                        reset = true;
                    }
                }
            }
            else if (item == Item.Header)
            {
                if (chunk.buffer[i] == '\n')
                {
                    if (index > 0 && memory[index-1] == '\r')
                    {
                        requests.insertBack(current);
                        current = Request();
                        count++;

                        item = Item.Method;
                        reset = true;
                    }
                }

                if (chunk.buffer[i] == ':')
                {
                    import core.stdc.string;
                    memory[index] = '\0';

                    if (strcmp(memory.ptr, "Connection".ptr) == 0)
                    {
                        header = HeaderField.CONNECTION;
                    }
                    item = Item.HeaderValue;
                    reset = true;
                }
            }
            else if (item == Item.HeaderValue)
            {
                import core.stdc.string;
                if (chunk.buffer[i] == '\n')
                {
                    if (index > 0 && memory[index-1] == '\r')
                    {
                        // heading and trailing whitespaces are optional
                        char* ptr = &memory[0];
                        if (isspace(memory[0]))
                        {
                            ptr = &memory[1];
                        }

                        if (index > 1)
                        {
                            if (isspace(memory[index-2]))
                            {
                                memory[index-2] = '\0';
                            }
                            else
                            {
                                memory[index-1] = '\0';
                            }
                        }

                        if (header == HeaderField.CONNECTION)
                        {
                            if (strcmp(ptr, "close".ptr) == 0)
                            {
                                current.keepAlive = false;
                            }
                            else if (strcmp(ptr, "keep-alive".ptr) == 0)
                            {
                                current.keepAlive = true;
                            }
                        }

                        item = Item.Header;
                        header = HeaderField.UNKNOWN;
                        reset = true;
                    }
                }
            }

            if (reset)
            {
                index = 0;
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
