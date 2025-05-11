module atlant.http.parser;

import atlant.http.session;
import atlant.http.chunk;
import atlant.utils.string;
import atlant.utils.list;

enum HeaderField
{
    UNKNOWN,
    CONNECTION
}

struct Request
{
    HttpMethod method;
    bool closeConnection;
    String s1;
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

    List!Request requests;
    // int index = 0;
    String memory;
    private Item item = Item.Method;
    Request current = Request();
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
                    memory.seal();

                    if (strcmp(memory.data, "HEAD".ptr) == 0)
                    {
                        current.method = HttpMethod.HEAD;
                    }
                    else if (strcmp(memory.data, "GET".ptr) == 0)
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
                    if (memory.index > 0)
                    {
                        // Omit trailing slash
                        char x = ' ';
                        memory.unget(&x);
                        if (x != '/')
                        {
                            memory.put(x);
                        }
                    }

                    // Seal, assign, detach
                    memory.seal();
                    current.s1 = memory;
                    memory.detach();
                    item = Item.HttpVersion;
                    reset = true;
                }
                else if (chunk.buffer[i] == '/')
                {
                    if (memory.index == 0)
                    {
                        // Omit leading slash
                        reset = true;
                    }
                    else
                    {
                        char x = ' ';
                        memory.unget(&x);
                        if (x != '/')
                        {
                            memory.put(x);
                        }
                    }
                }
            }
            else if (item == Item.HttpVersion)
            {
                if (chunk.buffer[i] == '\n')
                {
                    if (memory.index > 0 && memory.data[memory.index-1] == '\r')
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
                    if (memory.index > 0 && memory.data[memory.index-1] == '\r')
                    {
                        requests.add(current);
                        current = Request();
                        count++;

                        item = Item.Method;
                        reset = true;
                    }
                }

                if (chunk.buffer[i] == ':')
                {
                    import core.stdc.string;
                    memory.seal();

                    if (strcmp(memory.data, "Connection".ptr) == 0)
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
                    if (memory.index > 0 && memory.data[memory.index-1] == '\r')
                    {
                        // heading and trailing whitespaces are optional
                        char* ptr = &memory.data[0];
                        if (isspace(memory.data[0]))
                        {
                            ptr = &memory.data[1];
                        }

                        if (memory.index > 1)
                        {
                            if (isspace(memory.data[memory.index-2]))
                            {
                                memory.data[memory.index-2] = '\0';
                            }
                            else
                            {
                                memory.data[memory.index-1] = '\0';
                            }
                        }

                        if (header == HeaderField.CONNECTION)
                        {
                            if (strcmp(ptr, "close".ptr) == 0)
                            {
                                current.closeConnection = true;
                            }
                            else if (strcmp(ptr, "keep-alive".ptr) == 0)
                            {
                                current.closeConnection = false;
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
                memory.drop();
                memory = String();
                //index = 0;
            }
            else
            {
                memory.put(chunk.buffer[i]);
            }
        }
        return count;
    }
}
