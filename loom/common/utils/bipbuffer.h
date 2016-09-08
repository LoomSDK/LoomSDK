#ifndef BIPBUFFER_H
#define BIPBUFFER_H

typedef struct
{
    unsigned long int size;

    /* region A */
    unsigned int a_start, a_end;

    /* region B */
    unsigned int b_end;

    /* is B inuse? */
    int b_inuse;

    unsigned char data[];
} bipbuf_t;

/**
 * Create a new bip buffer.
 *
 * malloc()s space
 *
 * @param[in] size The size of the buffer */
bipbuf_t *bipbuf_new(const unsigned int size);

/**
 * Initialise a bip buffer. Use memory provided by user.
 *
 * No malloc()s are performed.
 *
 * @param[in] size The size of the array */
void bipbuf_init(bipbuf_t* me, const unsigned int size);

/**
 * Resize the bip buffer.
 *
 * If the provided new size is bigger, data is shifted around as to provide
 * as much usable free space as possible. Call after allocating more space.
 *
 * If the provided new size is smaller, data is shifted to fit inside. If the
 * new size is smaller than the number of bytes in use the behavior
 * is undefined. Call before shrinking available space.
 *
 * No malloc()s are performed.
 *
 */
void bipbuf_resize(bipbuf_t* me, const unsigned int size);

/**
 * Free the bip buffer */
void bipbuf_free(bipbuf_t *me);

/**
 * @param[in] data The data to be offered to the buffer
 * @param[in] size The size of the data to be offered
 * @return number of bytes offered */
int bipbuf_offer(bipbuf_t *me, const unsigned char *data, const int size);

/**
 * Look at data. Don't move cursor
 *
 * @param[in] len The length of the data to be peeked
 * @return data on success, NULL if we can't peek at this much data */
unsigned char *bipbuf_peek(const bipbuf_t* me, const unsigned int len);

/**
 * Get pointer to data to read. Move the cursor on.
 *
 * @param[in] len The length of the data to be polled
 * @return pointer to data, NULL if we can't poll this much data */
unsigned char *bipbuf_poll(bipbuf_t* me, const unsigned int size);

/**
 * @return the size of the bipbuffer */
int bipbuf_size(const bipbuf_t* me);

/**
 * @return 1 if buffer is empty; 0 otherwise */
int bipbuf_is_empty(const bipbuf_t* me);

/**
 * @return how much space we have assigned */
int bipbuf_used(const bipbuf_t* cb);

/**
 * @return bytes of unused space */
int bipbuf_unused(const bipbuf_t* me);

/**
* @return max bytes available for peek/poll */
int bipbuf_available(const bipbuf_t* me);

#endif /* BIPBUFFER_H */
