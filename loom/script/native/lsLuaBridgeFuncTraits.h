//==============================================================================

/**
 * Traits for function pointers.
 *
 * There are three types of functions: global, non-const member, and const member.
 * These templates determine the type of function, which class type it belongs to
 * if it is a class member, the const-ness if it is a member function, and the
 * type information for the return value and argument list.
 *
 * Expansions are provided for functions with up to 8 parameters. This can be
 * manually extended, or expanded to an arbitrary amount using C++11 features.
 */
template<typename MemFn, typename D = MemFn>
struct FuncTraits
{
};

/* Ordinary function pointers. */

template<typename R, typename D>
struct FuncTraits<R (*)(), D>
{
    static bool const isMemberFunction = false;
    typedef D      DeclType;
    typedef R      ReturnType;
    typedef None   Params;
    static R call(DeclType fp, TypeListValues<Params> )
    {
        return fp();
    }
};

template<typename R, typename P1, typename D>
struct FuncTraits<R (*)(P1), D>
{
    static bool const isMemberFunction = false;
    typedef D              DeclType;
    typedef R              ReturnType;
    typedef TypeList<P1>   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd);
    }
};

template<typename R, typename P1, typename P2, typename D>
struct FuncTraits<R (*)(P1, P2), D>
{
    static bool const isMemberFunction = false;
    typedef D                             DeclType;
    typedef R                             ReturnType;
    typedef TypeList<P1, TypeList<P2> >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename D>
struct FuncTraits<R (*)(P1, P2, P3), D>
{
    static bool const isMemberFunction = false;
    typedef D                                            DeclType;
    typedef R                                            ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3> > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4), D>
{
    static bool const isMemberFunction = false;
    typedef D                                                           DeclType;
    typedef R                                                           ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4> > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4, P5), D>
{
    static bool const isMemberFunction = false;
    typedef D                                                                          DeclType;
    typedef R                                                                          ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5> > > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4, P5, P6), D>
{
    static bool const isMemberFunction = false;
    typedef D                                                                                         DeclType;
    typedef R                                                                                         ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6> > > > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4, P5, P6, P7), D>
{
    static bool const isMemberFunction = false;
    typedef D                                                                                                        DeclType;
    typedef R                                                                                                        ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7> > > > > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4, P5, P6, P7, P8), D>
{
    static bool const isMemberFunction = false;
    typedef D                                                                                                                       DeclType;
    typedef R                                                                                                                       ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8> > > > > > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};

/* Non-const member function pointers. */

template<class T, typename R, typename D>
struct FuncTraits<R (T::*)(), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D      DeclType;
    typedef T      ClassType;
    typedef R      ReturnType;
    typedef None   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> const&)
    {
        return (obj->*fp)();
    }
};

template<class T, typename R, typename P1, typename D>
struct FuncTraits<R (T::*)(P1), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D              DeclType;
    typedef T              ClassType;
    typedef R              ReturnType;
    typedef TypeList<P1>   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename D>
struct FuncTraits<R (T::*)(P1, P2), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                             DeclType;
    typedef T                             ClassType;
    typedef R                             ReturnType;
    typedef TypeList<P1, TypeList<P2> >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                            DeclType;
    typedef T                                            ClassType;
    typedef R                                            ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3> > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                           DeclType;
    typedef T                                                           ClassType;
    typedef R                                                           ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4> > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                          DeclType;
    typedef T                                                                          ClassType;
    typedef R                                                                          ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5> > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                                         DeclType;
    typedef T                                                                                         ClassType;
    typedef R                                                                                         ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6> > > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                                                        DeclType;
    typedef T                                                                                                        ClassType;
    typedef R                                                                                                        ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7> > > > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7, P8), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                                                                       DeclType;
    typedef T                                                                                                                       ClassType;
    typedef R                                                                                                                       ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8> > > > > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename P9, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7, P8, P9), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                                                                                      DeclType;
    typedef T                                                                                                                                      ClassType;
    typedef R                                                                                                                                      ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8, TypeList<P9> > > > > > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename P9, typename P10, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7, P8, P9, P10), D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                                                                                                      DeclType;
    typedef T                                                                                                                                                      ClassType;
    typedef R                                                                                                                                                      ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8, TypeList<P9, TypeList<P10> > > > > > > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};
/* Const member function pointers. */

template<class T, typename R, typename D>
struct FuncTraits<R (T::*)() const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D      DeclType;
    typedef T      ClassType;
    typedef R      ReturnType;
    typedef None   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> const&)
    {
        return (obj->*fp)();
    }
};

template<class T, typename R, typename P1, typename D>
struct FuncTraits<R (T::*)(P1) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D              DeclType;
    typedef T              ClassType;
    typedef R              ReturnType;
    typedef TypeList<P1>   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename D>
struct FuncTraits<R (T::*)(P1, P2) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                             DeclType;
    typedef T                             ClassType;
    typedef R                             ReturnType;
    typedef TypeList<P1, TypeList<P2> >   Params;
    static R call(T const *const obj, R (T::*fp)(P1, P2) const,
                  TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                            DeclType;
    typedef T                                            ClassType;
    typedef R                                            ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3> > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                           DeclType;
    typedef T                                                           ClassType;
    typedef R                                                           ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4> > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                          DeclType;
    typedef T                                                                          ClassType;
    typedef R                                                                          ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5> > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                                         DeclType;
    typedef T                                                                                         ClassType;
    typedef R                                                                                         ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6> > > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                                                        DeclType;
    typedef T                                                                                                        ClassType;
    typedef R                                                                                                        ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7> > > > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7, P8) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                                                                       DeclType;
    typedef T                                                                                                                       ClassType;
    typedef R                                                                                                                       ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8> > > > > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename P9, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7, P8, P9) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                                                                                      DeclType;
    typedef T                                                                                                                                      ClassType;
    typedef R                                                                                                                                      ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8, TypeList<P9> > > > > > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename P9, typename P10, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7, P8, P9, P10) const, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                                                                                                      DeclType;
    typedef T                                                                                                                                                      ClassType;
    typedef R                                                                                                                                                      ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8, TypeList<P9, TypeList<P10> > > > > > > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};

#if defined (THROWSPEC)

/* Ordinary function pointers. */

template<typename R, typename D>
struct FuncTraits<R (*)() THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D      DeclType;
    typedef R      ReturnType;
    typedef None   Params;
    static R call(DeclType fp, TypeListValues<Params> const&)
    {
        return fp();
    }
};

template<typename R, typename P1, typename D>
struct FuncTraits<R (*)(P1) THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D              DeclType;
    typedef R              ReturnType;
    typedef TypeList<P1>   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd);
    }
};

template<typename R, typename P1, typename P2, typename D>
struct FuncTraits<R (*)(P1, P2) THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D                             DeclType;
    typedef R                             ReturnType;
    typedef TypeList<P1, TypeList<P2> >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename D>
struct FuncTraits<R (*)(P1, P2, P3) THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D                                            DeclType;
    typedef R                                            ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3> > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4) THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D                                                           DeclType;
    typedef R                                                           ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4> > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4, P5) THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D                                                                          DeclType;
    typedef R                                                                          ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5> > > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4, P5, P6) THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D                                                                                         DeclType;
    typedef R                                                                                         ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6> > > > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4, P5, P6, P7) THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D                                                                                                        DeclType;
    typedef R                                                                                                        ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7> > > > > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename D>
struct FuncTraits<R (*)(P1, P2, P3, P4, P5, P6, P7, P8) THROWSPEC, D>
{
    static bool const isMemberFunction = false;
    typedef D                                                                                                                       DeclType;
    typedef R                                                                                                                       ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8> > > > > > > >   Params;
    static R call(DeclType fp, TypeListValues<Params> tvl)
    {
        return fp(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                  tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};

/* Non-const member function pointers. */

template<class T, typename R, typename D>
struct FuncTraits<R (T::*)() THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D      DeclType;
    typedef T      ClassType;
    typedef R      ReturnType;
    typedef None   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> const&)
    {
        return (obj->*fp)();
    }
};

template<class T, typename R, typename P1, typename D>
struct FuncTraits<R (T::*)(P1) THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D              DeclType;
    typedef T              ClassType;
    typedef R              ReturnType;
    typedef TypeList<P1>   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename D>
struct FuncTraits<R (T::*)(P1, P2) THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                             DeclType;
    typedef T                             ClassType;
    typedef R                             ReturnType;
    typedef TypeList<P1, TypeList<P2> >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3) THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                            DeclType;
    typedef T                                            ClassType;
    typedef R                                            ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3> > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4) THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                           DeclType;
    typedef T                                                           ClassType;
    typedef R                                                           ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4> > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5) THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                          DeclType;
    typedef T                                                                          ClassType;
    typedef R                                                                          ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5> > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6) THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                                         DeclType;
    typedef T                                                                                         ClassType;
    typedef R                                                                                         ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6> > > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7) THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                                                        DeclType;
    typedef T                                                                                                        ClassType;
    typedef R                                                                                                        ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7> > > > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7, P8) THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = false;
    typedef D                                                                                                                       DeclType;
    typedef T                                                                                                                       ClassType;
    typedef R                                                                                                                       ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8> > > > > > > >   Params;
    static R call(T *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};

/* Const member function pointers. */

template<class T, typename R, typename D>
struct FuncTraits<R (T::*)() const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D      DeclType;
    typedef T      ClassType;
    typedef R      ReturnType;
    typedef None   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> const&)
    {
        (void)tvl;
        return (obj->*fp)();
    }
};

template<class T, typename R, typename P1, typename D>
struct FuncTraits<R (T::*)(P1) const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D              DeclType;
    typedef T              ClassType;
    typedef R              ReturnType;
    typedef TypeList<P1>   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename D>
struct FuncTraits<R (T::*)(P1, P2) const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                             DeclType;
    typedef T                             ClassType;
    typedef R                             ReturnType;
    typedef TypeList<P1, TypeList<P2> >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3) const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                            DeclType;
    typedef T                                            ClassType;
    typedef R                                            ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3> > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4) const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                           DeclType;
    typedef T                                                           ClassType;
    typedef R                                                           ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4> > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5) const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                          DeclType;
    typedef T                                                                          ClassType;
    typedef R                                                                          ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5> > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6) const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                                         DeclType;
    typedef T                                                                                         ClassType;
    typedef R                                                                                         ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6> > > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7) const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                                                        DeclType;
    typedef T                                                                                                        ClassType;
    typedef R                                                                                                        ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7> > > > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd);
    }
};

template<class T, typename R, typename P1, typename P2, typename P3, typename P4, typename P5, typename P6, typename P7, typename P8, typename D>
struct FuncTraits<R (T::*)(P1, P2, P3, P4, P5, P6, P7, P8) const THROWSPEC, D>
{
    static bool const isMemberFunction      = true;
    static bool const isConstMemberFunction = true;
    typedef D                                                                                                                       DeclType;
    typedef T                                                                                                                       ClassType;
    typedef R                                                                                                                       ReturnType;
    typedef TypeList<P1, TypeList<P2, TypeList<P3, TypeList<P4, TypeList<P5, TypeList<P6, TypeList<P7, TypeList<P8> > > > > > > >   Params;
    static R call(T const *const obj, DeclType fp, TypeListValues<Params> tvl)
    {
        return (obj->*fp)(tvl.hd, tvl.tl.hd, tvl.tl.tl.hd, tvl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.hd,
                          tvl.tl.tl.tl.tl.tl.tl.hd, tvl.tl.tl.tl.tl.tl.tl.tl.hd);
    }
};
#endif
