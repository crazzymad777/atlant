module atlant.utils.list;

struct ListNode(T)
{
    alias Node = ListNode!T;
    Node* prev;
    Node* next;
    T value;
}

// Double linked list with size
struct List(T)
{
    alias Node = ListNode!T;

    private Node* head;
    private Node* tail;
    size_t length;
    size_t add(T value)
    {
        import core.stdc.stdlib;

        Node* node = cast(Node*) malloc(Node.sizeof);
        node.value = value;
        Node* last = tail;
        if (tail == null)
        {
            node.prev = null;
            node.next = null;
            head = node;
            tail = node;
        }
        else
        {
            tail.next = node;
            node.prev = tail;
            node.next = null;
            tail = node;
        }

        length++;
        return length;
    }

    Node* front()
    {
        return head;
    }

    void removeFront()
    {
        if (length > 0)
        {
            Node* next = head.next;
            if (next is null)
            {
                tail = null;
                head = null;
            }
            else
            {
                import core.stdc.stdlib;
                free(head);

                head = next;
                head.prev = null;
            }
            length--;
        }
    }
}
