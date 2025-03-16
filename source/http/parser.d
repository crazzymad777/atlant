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
                        index = 0;
                    }
                }
            }
            else if (chunk.buffer[i] == ':')
            {
            }
            else if (chunk.buffer[i] == ' ')
            {

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
