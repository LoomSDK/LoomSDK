/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "loom/common/assets/assets.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platformDisplay.h"
#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/script/native/core/system/lmString.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/runtime/lsLuaState.h"

#include "loom/common/core/performance.h"

using namespace LS;

lmDefineLogGroup(cssLogGroup, "css", 1, LoomLogWarn);

/*
 * Style contains a dictionary of properties, a list of attributes and a selector
 */
class Style
{
    public:

        Style(const utString& selector)
        : _selector(selector)
        {
        }

        /*
         * A constructor used by LS native bindings
         */
        Style()
        : _selector("")
        {
        }

        /*
         * Returns the number of unique properties the style defines.
         */
        UTsize getPropertyCount() const
        {
            return _properties.size();
        }

        /*
         * Returns the name of the property at given index. Should not be called
         * with an index that is out of bounds.
         */
        const char* getPropertyNameByIndex(UTsize index) const
        {
            return _properties.keyAt(index).str().c_str();
        }

        /*
         * Returns the value of the property at given index as a string. Should not be called
         * with an index that is out of bounds.
         */
        const char* getPropertyValueByIndex(UTsize index) const
        {
            return _properties.at(index).c_str();
        }

        /*
         * Returns the value of the property with the given name as a string. If such a
         * property doesn't exist, NULL is returned.
         */
        const char* getPropertyValue(const char* name) const
        {
            utHashedString key(name);
            if (_properties.find(key) != UT_NPOS)
            {
                return _properties[key]->c_str();
            }

            return NULL;
        }

        /*
         * Sets the value of a property with the given name. If a property with such a name
         * already exists, the old one is overriden.
         */
        void setPropertyValue(const char* name, const char* value)
        {
            utHashedString key(name);
            _properties.set(key, value);
        }

        /*
         * Returns true if the style defines a property with the given name, false othervise.
         */
        bool hasProperty(const char* name) const
        {
            utHashedString key(name);
            return _properties.find(key) != UT_NPOS;
        }

        /*
         * Removes the property with the given name, if it exists.
         */
        void removeProperty(const char* name)
        {
            utHashedString key(name);
            _properties.remove(key);
        }

        /* Adds an attribute with the given name. Attributes are not checked for duplicates,
         * for all current use cases, that doesn't matter. We only care about the existance
         * of an attribute.
         */
        void addAttribute(const utString& name)
        {
            _attributes.push_back(name);
        }

        /*
         * Checks if the style matches the given attributes. If there are any attributes
         * on the style that are not on the hash table, return false or true otherwise.
         */
        bool matchAttributes(const utHashTable<utHashedString, bool>& matches) const
        {
            for (UTsize i = 0; i < _attributes.size(); i++)
            {
                utHashedString key(_attributes[i]);
                if (matches.find(key) == UT_NPOS)
                {
                    // found a match, but was false: style does not completely match
                    if (!matches[key])
                        return false;
                }
                else
                {
                    // attribute not found, doesn't match
                    return false;
                }
            }

            // Didn't find anything not matching, it's a match
            return true;
        }

        /*
         * Return the name (selector) this style responds to.
         */
        const char* getName() const
        {
            return _selector.c_str();
        }

        /*
         * Set the name (selector) this style responds to.
         */
        void setName(const char* name)
        {
            _selector = name;
        }

        /*
         * Adds a new property or overrides an existing one. 'key' is the name
         * of the property and 'value' it's value.
         */
        void addDeclaration(const utString& key, const utString& value)
        {
            _properties.set(utHashedString(key), value);
        }

        /*
         * Merges another style into the this style. The properties of the other
         * style are added or they override the properties of this style.
         */
        void merge(const Style* other)
        {
            utHashTableIterator<utHashTable<utHashedString, utString> > i(other->_properties.iterator());
            while (i.hasMoreElements())
            {
                // Add a new property or override an existing one
                _properties.set(i.peekNextKey(), i.peekNextValue());
                i.next();
            }
        }

        /*
         * Return the selector as a representation of the object
         */
        const char* toString() const
        {
            return _selector.c_str();
        }

        /*
         * Create a new instance of the Style with the same name, properties and attributes.
         * The instance will be garbage collected by LoomScript.
         */
        int clone(lua_State* L)
        {
            // Get the LS type - we can't statically store it, that would fail with live assembly reload
            Type* type = LSLuaState::getLuaState(L)->getType("loom.css.Style");

            // Create an instance on top of the stack
            lsr_createinstance(L, type);

            // Copy the members
            Style *o = (Style *)lualoom_getnativepointer(L, -1);
            o->_selector = _selector;
            o->_properties = _properties;
            o->_attributes = _attributes;

            return 1;
        }

    private:

        // The selector this style responds to.
        utString _selector;

        // A hash table where the properties are stored.
        utHashTable<utHashedString, utString> _properties;

        // A collection of attributes defined for this style.
        utArray<utString> _attributes;
};

/*
 * A simple parser for CSS source. It doesn't work well with CSS standards,
 * but is fast and does what we need it to.
 */
class Parser
{
    public:

        static const char* skipWS(const char* p, const char* end)
        {
            while (p < end)
            {
                if (p[0] == ' ' ||
                    p[0] == '\n' ||
                    p[0] == '\r' ||
                    p[0] == '\t')
                {
                    p++;
                    continue;
                }
                else
                {
                    break;
                }
            }

            return p;
        }

        static const char* readUntil(const char* p, const char* end, char c)
        {
            while (p < end && p[0] != c)
            {
                p++;
            }

            return p;
        }

        static const char* skipCommentsAndWS(const char* p, const char* end)
        {
            p = skipWS(p, end);

            if (p + 1 < end &&
                p[0] == '/' &&
                p[1] == '*')
            {
                p += 2;

                do
                {
                    p = readUntil(p, end, '*');
                    p++;
                }
                while (p < end && p[0] != '/');
                p++;
            }

            p = skipWS(p, end);

            if (p + 1 < end &&
                p[0] == '/' &&
                p[1] == '*')
            {
                p = skipCommentsAndWS(p, end);
            }

            return p;
        }

        static utString readSelector(const char** pp, const char* end)
        {
            const char* p = *pp;
            const char* start = p;

            while (p < end)
            {
                if (p[0] == '[' ||
                    p[0] == '\n' ||
                    p[0] == '\r' ||
                    p[0] == '\t' ||
                    p[0] == ' ' ||
                    p[0] == '{')
                {
                    *pp = p;
                    utString selector;
                    selector.assign(start, p - start);
                    return selector;
                }

                p++;
            }

            // Move the pointer forward anyway, try to save this
            *pp = p;

            lmLogError(cssLogGroup, "Syntax error, error reading CSS selector.");
            return "";
        }

        static const char* readSelectorAttributes(Style* style, const char* p, const char* end)
        {
            // skip [
            p++;

            p = skipCommentsAndWS(p, end);

            if (p >= end)
                return end;

            const char* start = p;

            while (p < end && p[0] != '\n')
            {
                if (p[0] == ' ' ||
                    p[0] == ',' ||
                    p[0] == ']')
                {
                    utString attribute;
                    attribute.assign(start, p - start);
                    style->addAttribute(attribute);

                    if (p[0] == ' ')
                    {
                        p = skipCommentsAndWS(p, end);
                        start = p;
                    }

                    if (p[0] == ',')
                    {
                        p++;
                        start = p;
                        continue;
                    }

                    if (p[0] == ']')
                    {
                        break;
                    }
                }

                p++;
            }

            // skip ]
            p++;

            return p;
        }

        static const char* readKey(const char* p, const char* end, utString& key)
        {
            const char* start = p;
            while (p < end && p[0] != ' ' && p[0] != ':')
            {
                p++;
            }

            key.assign(start, p - start);

            return p;
        }

        static const char* parseValueString(const char* p, const char* end, utString& value, char quote)
        {
            // skip quote
            p++;

            const char* start = p;
            while (p < end && p[0] != quote && p[0] != '\n')
            {
                p++;
            }

            value.assign(start, p - start);

            if (p >= end)
            {
                lmLogError(cssLogGroup, "Syntax error: Unexpected EOF");
                return p;
            }

            if (p[0] == '\n')
            {
                lmLogError(cssLogGroup, "Syntax error: Unexpected newline, unterminated string");
                return p;
            }

            if (p[0] == quote)
            {
                // skip quote
                p++;
            }

            return p;
        }

        static const char* parseValue(const char* p, const char* end, utString& value)
        {
            const char* start = p;

            while (p < end && p[0] != ';' && p[0] != '\n')
            {
                p++;
            }

            value.assign(start, p - start);

            if (p >= end)
            {
                lmLogError(cssLogGroup, "Syntax error: Unexpected EOF");
                return p;
            }

            if (p[0] == '\n')
            {
                lmLogError(cssLogGroup, "Syntax error: Unexpected newline, expected ';'");
            }

            return p;
        }

        static const char* parseProperty(Style* style, const char* p, const char* end)
        {
            utString key;
            utString value;

            p = skipCommentsAndWS(p, end);
            p = readKey(p, end, key);
            p = skipCommentsAndWS(p, end);

            if (p >= end)
            {
                lmLogError(cssLogGroup, "Syntax error: Unexpected EOF");
                return p;
            }

            if (p[0] != ':')
            {
                lmLogError(cssLogGroup, "Syntax error: Expected a colon after property name");
                p = readUntil(p, end, '\n'); // skip to a newline, possibly report more errors
                return p;
            }

            // skip :
            p++;

            p = skipCommentsAndWS(p, end);

            if (p[0] == '\'')
            {
                p = parseValueString(p, end, value, '\'');
            }
            else if (p[0] == '"')
            {
                p = parseValueString(p, end, value, '"');
            }
            else
            {
                p = parseValue(p, end, value);
            }

            p = skipCommentsAndWS(p, end);

            if (p[0] != ';')
            {
                lmLogError(cssLogGroup, "Syntax error: Expected a semicolon at the end of property declaration");
            }
            else
            {
                // Skip ;
                p++;
            }

            style->addDeclaration(key, value);

            return p;
        }

        static const char* readPropertyBlock(Style* style, const char* p, const char* end)
        {
            // skip {
            p++;

            p = skipCommentsAndWS(p, end);

            while (p < end && p[0] != '}')
            {
                p = parseProperty(style, p, end);
                p = skipCommentsAndWS(p, end);
            }

            // skip }
            p++;

            return p;
        }
};

/*
 * The stylesheet is a collection of Styles in a CSS file/source.
 */
class StyleSheet
{
    public:

        /*
         * The constructor. It will set the stylesheet attributes based on the current
         * platform and display.
         */
        StyleSheet()
        : _name("undefined")
        {
            display_profile dp = display_getProfile();
            switch (dp)
            {
                case PROFILE_DESKTOP:
                    defineAttribute("desktop", true);
                    break;
                case PROFILE_MOBILE_SMALL:
                    defineAttribute("small", true);
                    break;
                case PROFILE_MOBILE_NORMAL:
                    defineAttribute("normal", true);
                    break;
                case PROFILE_MOBILE_LARGE:
                    defineAttribute("large", true);
                    break;
                default:
                    lmAssert(0, "Unhandled display profile!");
            }

            switch (LOOM_PLATFORM)
            {
                case LOOM_PLATFORM_WIN32:
                    defineAttribute("windows", true);
                    break;
                case LOOM_PLATFORM_OSX:
                    defineAttribute("osx", true);
                    break;
                case LOOM_PLATFORM_IOS:
                    defineAttribute("ios", true);
                    break;
                case LOOM_PLATFORM_ANDROID:
                    defineAttribute("android", true);
                    break;
                case LOOM_PLATFORM_LINUX:
                    defineAttribute("linux", true);
                    break;
                default:
                    lmAssert(0, "Unhandled platform!");
            }
        }

        ~StyleSheet()
        {
            if (_source.size() > 0)
            {
                loom_asset_unsubscribe(_source.c_str(), &StyleSheet::reloadCallback, this);
            }

            clear();
        }

        /*
         * Set the name of this stylesheet.
         */
        void setName(const char* name)
        {
            _name = name;
        }

        /*
         * Get the name of this stylesheet.
         */
        const char* getName() const
        {
            return _name.c_str();
        }

        /*
         * Set the source file name for this stylesheet. The source will be loaded
         * as an asset, parsed for rules and the stylesheet will subscribe for live updates.
         */
        void setSource(const char* path)
        {
            // If the stylesheet was loaded from an asset already, remove the previous
            // subscription.
            if (_source.size() > 0)
            {
                loom_asset_unsubscribe(_source.c_str(), &StyleSheet::reloadCallback, this);
            }

            _source = path;

            // Clear previous styles
            clear();

            // Parse the new asset sources
            parseSource(getAssetSource());

            // Subscribe for changes of the asset (live reload)
            loom_asset_subscribe(_source.c_str(), &StyleSheet::reloadCallback, this, false);

            // Invoke the delegate that the source has changed
            _onUpdateDelegate.invoke();
        }

        /*
         * Return the name of the source file this stylesheet was loaded from.
         * If the stylesheet was not loaded from a file, an empty string will
         * be returned.
         */
        const char* getSource() const
        {
            return _source.c_str();
        }

        /*
         * Parses a stylesheet from a string. If this stylesheet was using an asset
         * before, live reloading will be disabled.
         */
        void parseCSS(const char* css)
        {
            // If the stylesheet was loaded from an asset, and now we're parsing
            // a string, we need to unsubscribe from live reloads.
            if (_source.size() > 0)
            {
                loom_asset_unsubscribe(_source.c_str(), &StyleSheet::reloadCallback, this);
            }

            // Do the actual parsing
            parseSource(css);

            // Invoke the delegate that the source has changed
            _onUpdateDelegate.invoke();
        }

        /*
         * Clears all the styles (rules). Attributes and the name are left unchanged,
         * they are not dependant on the source of the stylesheet.
         */
        void clear()
        {
            utHashTableIterator<utHashTable<utHashedString, utArray<Style *> > > i(_styles.iterator());
            while (i.hasMoreElements())
            {
                utArray<Style *>& styles = i.peekNextValue();

                for (UTsize j = 0; j < styles.size(); j++)
                {
                    lmDelete(NULL, styles[j]);
                }

                i.next();
            }

            _styles.clear();
        }

        /*
         * Checks the stylesheet for the presence of a style with a specific selector.
         * Returns true if it was found, false otherwise.
         */
        bool hasStyle(const char* selector)
        {
            return _styles.find(utHashedString(selector)) != UT_NPOS;
        }

        /*
         * Return a string representation of this object. For now this is it's name.
         */
        const char* toString()
        {
            return _name.c_str();
        }

        /*
         * Add a new style with the given name (selector). If an existing style with
         * the same selector already exists, it's added to an array.
         * There are multiple styles possible with the same selector, they might
         * have different attributes.
         * Note that the style's own selector doesn't matter at lookup.
         */
        void newStyle(const char* selector, Style* style)
        {
            utHashedString key(selector);
            if (_styles.find(key) != UT_NPOS)
            {
                utArray<Style *>* styles = _styles.get(key);
                styles->push_back(style);
            }
            else
            {
                utArray<Style *> styles;
                styles.push_back(style);
                _styles.set(key, styles);
            }
        }

        /*
         * Get a composite style from the given styleNames (selectors, separated with a space).
         * The styles found will be merged into a new style that will be returned.
         */
        int getStyle(lua_State* L)
        {
            const char* rawSelector = lua_tostring(L, -1);

            // Get the LS type - we can't statically store it, that would fail with live assembly reload
            Type* type = LSLuaState::getLuaState(L)->getType("loom.css.Style");

            // Create an instance on top of the stack
            lsr_createinstance(L, type);

            // Copy the members
            Style *result = (Style *)lualoom_getnativepointer(L, -1);
            result->setName(rawSelector);

            // Create a copy of the selector string we will be parsing
            utString selector(rawSelector);

            // Parse until we run out of selectors
            while(selector.size())
            {
                // Each selector should be separated with a single space
                UTsize i = selector.find(' ');

                // If there is a space at index 0,
                // there were multiple spaces between the selectors.
                // Remove a space and try again
                if (i == 0)
                {
                    selector.erase(0, 1);
                    continue;
                }

                utString singleSelector;
                if (i != UT_NPOS)
                {
                    // Extract a single selector and erase it and a space from
                    // the parsing string
                    singleSelector = selector.substr(0, i);
                    selector.erase(0, i + 1);
                }
                else
                {
                    // There is no more spaces, parse the remainder of string
                    // as the last selector
                    singleSelector = selector.substr(0);
                    selector.erase(0, selector.size());
                }

                // Look up a styles with matching selectors and attributes and
                // merge them to the result
                utHashedString key(singleSelector);
                if (_styles.find(key) != UT_NPOS)
                {
                    utArray<Style *> styles = *_styles[key];

                    for (UTsize i = 0; i < styles.size(); i++)
                    {
                        if (styles[i]->matchAttributes(_attributes))
                            result->merge(styles[i]);
                    }
                }
            }

            return 1;
        }

        LOOM_DELEGATE(onUpdate);

    private:

        /*
         * Defines an attribute on the stylesheet. Child styles must be compatible
         * with these attributes to be enabled.
         */
        void defineAttribute(const char* name, bool value)
        {
            utHashedString key(name);
            _attributes.set(key, value);
        }

        /*
         * The actual CSS parsing code. Creates the styles from source.
         */
        void parseSource(const char* css)
        {
            LOOM_PROFILE_SCOPE(CSS_PARSE_SOURCE);

            const char* end = css + strlen(css);

            while (css < end)
            {
                const char* begin = css;
                css = Parser::skipCommentsAndWS(css, end);

                // Parse the selector
                utString selector = Parser::readSelector(&css, end);

                Style* style = lmNew(NULL) Style(selector);

                // Optionally parse the style attribute
                if (css[0] == '[')
                {
                    css = Parser::readSelectorAttributes(style, css, end);
                }

                css = Parser::skipCommentsAndWS(css, end);

                if (css[0] != '{')
                {
                    lmLogError(cssLogGroup, "Syntax error: property block expected.");
                }

                // Parse the properties
                css = Parser::readPropertyBlock(style, css, end);

                // Add the parsed style
                newStyle(selector.c_str(), style);

                css = Parser::skipCommentsAndWS(css, end);
            }
        }

        /*
         * Loads the CSS source from an asset and returns the string pointer.
         */
        const char* getAssetSource() const
        {
            void * data = loom_asset_lock(_source.c_str(), LATText, 1);
            if (data == NULL)
            {
                lmLogWarn(cssLogGroup, "Unable to lock the asset for CSS %s", _source.c_str());
                return NULL;
            }
            loom_asset_unlock(_source.c_str());

            return static_cast<char*>(data);
        }

        /*
         * Live reload callback. Loads the asset, parses it and invokes an update delegate.
         */
        static void reloadCallback(void *payload, const char *name)
        {
            StyleSheet* obj = static_cast<StyleSheet*>(payload);

            obj->clear();
            obj->parseSource(obj->getAssetSource());

            // Invoke the delegate that the source has changed
            obj->_onUpdateDelegate.invoke();
        }

        // The name of the stylesheet
        utString _name;

        // The asset path, if any
        utString _source;

        // A dictionary of styles, keyed by selector
        utHashTable<utHashedString, utArray<Style*> > _styles;

        // Defined attributes on the stylesheet. These are generated
        // along with the object and the styles must match these to be valid.
        utHashTable<utHashedString, bool> _attributes;
};

/*
 * Applys a style to a LoomScript object through reflection. Property values of a
 * style will be applied to fields or properties of the object where the names match.
 */
class StyleApplicator
{
    public:

        StyleApplicator()
        {
        }

        static int applyStyle(lua_State* L)
        {
            LOOM_PROFILE_SCOPE(CSS_STYLE_APPLICATOR);
            // Get target object and Style on top of the stack
            lmAssert(lua_gettop(L) == 2, "applyStyle expects 2 arguments");

            // Ignore the call if any of the arguments is nil
            if (lua_isnil(L, -2) || lua_isnil(L, -1))
            {
                // clean up the stack
                lua_pop(L, 2);
                return 0;
            }

            Style* style = (Style *)lualoom_getnativepointer(L, -1, "loom.css.Style");
            // Pop the Style from the stack
            lua_pop(L, 1); // pop arguments

            // Get the type of the target object
            Type* objType = lsr_gettype(L, 1);
            // Save the target object reference for later, this pops the value from the stack
            int objref = luaL_ref(L, LUA_REGISTRYINDEX);

            // Iterate through the style properties
            for (UTsize i = 0; i < style->getPropertyCount(); i++)
            {
                const char* propertyName = style->getPropertyNameByIndex(i);
                const char* value = style->getPropertyValueByIndex(i);

                // Try to find a field or a property
                FieldInfo* fieldInfo = objType->findFieldInfoByName(propertyName);
                PropertyInfo* propertyInfo = objType->findPropertyInfoByName(propertyName);

                Type* propType = NULL;

                // Get the type of the field/property
                if (fieldInfo)
                {
                    propType = fieldInfo->getType();
                }
                else if (propertyInfo)
                {
                    propType = propertyInfo->getType();
                }
                else
                {
                    // Property or field with such a name doesn't exist, skip it.
                    continue;
                }

                // We only support basic type conversions
                if (propType->getFullName() == "system.String")
                {
                    if (fieldInfo)
                        setFieldString(L, fieldInfo, objref, value);
                    else
                        setPropertyString(L, propertyInfo, objref, value);
                }
                else if (propType->getFullName() == "system.Number")
                {
                    if (fieldInfo)
                        setFieldNumber(L, fieldInfo, objref, value);
                    else
                        setPropertyNumber(L, propertyInfo, objref, value);
                }
                else if (propType->getFullName() == "system.Boolean")
                {
                    if (fieldInfo)
                        setFieldString(L, fieldInfo, objref, value);
                    else
                        setPropertyBoolean(L, propertyInfo, objref, value);
                }
                else
                {
                    lmAssert(0, "Loom CSS does not support complex types yet. Please use String, Number, or Boolean");
                }

            }

            // Unreference the stored target object reference
            luaL_unref(L, LUA_REGISTRYINDEX, objref);

            return 0;
        }

    private:

        static void setFieldString(lua_State* L, FieldInfo* fieldInfo, int objref, const char* value)
        {
            // Arg 1: push a nil to satisfy setValue
            lua_pushnil(L);

            // Arg 1: the object instance we're calling a setter of
            lua_rawgeti(L, LUA_REGISTRYINDEX, objref);

            // Arg 2: the value argument
            lua_pushstring(L, value); // push the string on the stack

            fieldInfo->setValue(L);

            lua_pop(L, 3); // setValue doesn't pop anything, pop everything we pushed
        }

        static void setFieldNumber(lua_State* L, FieldInfo* fieldInfo, int objref, const char* value)
        {
            // Arg 1: push a nil to satisfy setValue
            lua_pushnil(L);

            // Arg 2: the object instance we're calling a setter of
            lua_rawgeti(L, LUA_REGISTRYINDEX, objref);

            // Arg 2: the value argument, convert from string to number first
            lua_pushstring(L, value); // push the string on the stack
            lua_insert(L, 1); // the string needs to be on stack index 1
            LS::loom_strToNumber(L); // convert the string at stack index 1, result will be on top of the stack
            lua_remove(L, 1); // remove the string value

            fieldInfo->setValue(L);

            lua_pop(L, 3); // setValue doesn't pop anything, pop everything we pushed
        }

        static void setFieldBoolean(lua_State* L, FieldInfo* fieldInfo, int objref, const char* value)
        {
            // Arg 1: push a nil to satisfy setValue
            lua_pushnil(L);

            // Arg 1: the object instance we're calling a setter of
            lua_rawgeti(L, LUA_REGISTRYINDEX, objref);

            // Arg 2: the value argument, convert from string to boolean first
            lua_pushstring(L, value); // push the string on the stack
            lua_insert(L, 1); // the string needs to be on stack index 1
            LS::loom_strToBoolean(L); // convert the string at stack index 1, result will be on top of the stack
            lua_remove(L, 1); // remove the string value

            fieldInfo->setValue(L);

            lua_pop(L, 3); // setValue doesn't pop anything, pop everything we pushed
        }

        static void setPropertyString(lua_State* L, PropertyInfo* propertyInfo, int objref, const char* value)
        {
            // Arg 1: push a nil to satisfy _invokeSingle
            lua_pushnil(L);

            // Arg 2: the object instance we're calling a setter of
            lua_rawgeti(L, LUA_REGISTRYINDEX, objref);

            // Arg 3: the value argument
            lua_pushstring(L, value); // push the string on the stack

            propertyInfo->getSetMethod()->_invokeSingle(L);

            lua_pop(L, 1); // pop the nil we pushed earlier
        }

        static void setPropertyNumber(lua_State* L, PropertyInfo* propertyInfo, int objref, const char* value)
        {
            // Arg 1: push a nil to satisfy _invokeSingle
            lua_pushnil(L);

            // Arg 2: the object instance we're calling a setter of
            lua_rawgeti(L, LUA_REGISTRYINDEX, objref);

            // Arg 3: the value argument, convert from string to number first
            lua_pushstring(L, value); // push the string on the stack
            lua_insert(L, 1); // the string needs to be on stack index 1
            LS::loom_strToNumber(L); // convert the string at stack index 1, result will be on top of the stack
            lua_remove(L, 1); // remove the string value

            propertyInfo->getSetMethod()->_invokeSingle(L);

            lua_pop(L, 1); // pop the nil we pushed earlier
        }

        static void setPropertyBoolean(lua_State* L, PropertyInfo* propertyInfo, int objref, const char* value)
        {
            // Arg 1: push a nil to satisfy _invokeSingle
            lua_pushnil(L);

            // Arg 2: the object instance we're calling a setter of
            lua_rawgeti(L, LUA_REGISTRYINDEX, objref);

            // Arg 3: the value argument, convert from string to boolean first
            lua_pushstring(L, value); // push the string on the stack
            lua_insert(L, 1); // the string needs to be on stack index 1
            LS::loom_strToBoolean(L); // convert the string at stack index 1, result will be on top of the stack
            lua_remove(L, 1); // remove the string value

            propertyInfo->getSetMethod()->_invokeSingle(L);

            lua_pop(L, 1); // pop the nil we pushed earlier
        }
};

static int registerCSSParser(lua_State *L)
{
    beginPackage(L, "loom.css")

        .beginClass<Style>("Style")

            .addConstructor<void (*)()>()

            .addMethod("__pget_propertyCount", &Style::getPropertyCount)
            .addMethod("getPropertyNameByIndex", &Style::getPropertyNameByIndex)
            .addMethod("getPropertyValueByIndex", &Style::getPropertyValueByIndex)
            .addMethod("getPropertyValue", &Style::getPropertyValue)
            .addMethod("hasProperty", &Style::hasProperty)
            .addMethod("removeProperty", &Style::removeProperty)
            .addMethod("setPropertyValue", &Style::setPropertyValue)
            .addProperty("styleName", &Style::getName)

            .addMethod("merge", &Style::merge)
            .addMethod("toString", &Style::toString)
            .addLuaFunction("clone", &Style::clone)

        .endClass()

        .beginClass<StyleSheet>("StyleSheet")

            .addConstructor<void (*)()>()

            .addProperty("name", &StyleSheet::getName, &StyleSheet::setName)
            .addProperty("source", &StyleSheet::getSource, &StyleSheet::setSource)

            .addMethod("parseCSS", &StyleSheet::parseCSS)
            .addMethod("clear", &StyleSheet::clear)
            .addMethod("hasStyle", &StyleSheet::hasStyle)
            .addMethod("toString", &StyleSheet::toString)
            .addMethod("newStyle", &StyleSheet::newStyle)
            .addLuaFunction("getStyle", &StyleSheet::getStyle)

            .addVarAccessor("_onUpdate", &StyleSheet::getonUpdateDelegate)

        .endClass()

        .beginClass<StyleApplicator>("StyleApplicator")

            .addConstructor<void (*)()>()

            .addStaticLuaFunction("_applyStyle", &StyleApplicator::applyStyle)

        .endClass()

    .endPackage();

    return 0;
}

void installCSSParser()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(Style, registerCSSParser);
    LOOM_DECLARE_MANAGEDNATIVETYPE(StyleSheet, registerCSSParser);
    LOOM_DECLARE_MANAGEDNATIVETYPE(StyleApplicator, registerCSSParser);
}
