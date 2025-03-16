module atlant.http.parser;

import atlant.http.session;
import atlant.http.chunk;

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
    int index;
    char[1024] memory;
    private Item item = Item.Method;

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
                            count++;
                        }
                        else
                        {
                            item = Item.Header;
                        }
                        index = 0;
                    }
                }
            }
            else if (chunk.buffer[i] == ':')
            {
                item = Item.HeaderSemicolon;
            }
            else if (chunk.buffer[i] == ' ')
            {
                if (item == Item.Method)
                {
                    item = Item.Path;
                    index = 0;
                }
                else if (item == Item.Path)
                {
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
