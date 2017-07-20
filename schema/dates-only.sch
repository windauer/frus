<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:functx="http://www.functx.com">
    <title>FRUS TEI Rules - Date Rules</title>
    
    <p>This schematron file contains only the date-related rules from frus.sch.</p>
    
    <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
    <ns prefix="frus" uri="http://history.state.gov/frus/ns/1.0"/>
    <ns prefix="xml" uri="http://www.w3.org/XML/1998/namespace"/>
    
    <let name="category-ids" value="//tei:category/@xml:id"/>
    
    <pattern id="pointer-checks">
        <title>Ref and Pointer Checks</title>
        <rule context="tei:date[@ana]">
            <assert test="substring-after(@ana, '#') = $category-ids">date/@ana='<value-of select="@ana"/>' is an invalid value.  No category has been defined with an @xml:id corresponding to this value.</assert>
        </rule>
    </pattern>
    
    <pattern id="dateline-date-checks">
        <title>Dateline Date Checks</title>
        <rule context="tei:dateline[matches(., 'undated', 'i')]">
            <assert test="exists(.//tei:date)">Please tag "undated" in this dateline with a &lt;date&gt; element.</assert>
        </rule>
        <rule context="tei:dateline">
            <assert test=".//tei:date">Datelines must contain a date element</assert>
        </rule>
        <rule context="tei:date[ancestor::tei:dateline and not(ancestor::frus:attachment)]">
            <assert role="warn" test="@*">Dates should have @when (for supplied single dates), @from/@to (for supplied date ranges), or @notBefore/@notAfter (for inferred date ranges)</assert>
            <assert test="normalize-space(.) ne ''">Dateline date cannot be empty.</assert>
            <assert test="
                (@from and @to) 
                or 
                (not(@from) and not(@to))
                ">Dateline date @from must have a corresponding @to.</assert>
            <assert test="
                (@notBefore and @notAfter) 
                or 
                (not(@notBefore) and not(@notAfter))
                ">Dateline date @notBefore must have a corresponding @notAfter.</assert>
            <assert role="warn" test="
                (@notBefore and @notAfter and @ana) 
                or 
                (not(@notBefore) and not(@notAfter))
                ">Missing @ana explaining the analysis used to determine @notBefore and @notAfter.</assert>
            <assert test="
                every $date in @when
                satisfies
                (
                (matches($date, '^\d{4}$') and ($date || '-01-01') castable as xs:date)
                or
                (matches($date, '^\d{4}-\d{2}$') and ($date || '-01') castable as xs:date)
                or
                $date castable as xs:date
                or
                $date castable as xs:dateTime
                )
                ">Dateline date @when values must be YYYY, YYYY-MM, or xs:date or xs:dateTime</assert>
            <assert test="
                every $date in (@from, @to, @notBefore, @notAfter) 
                satisfies 
                (
                $date castable as xs:date 
                or 
                $date castable as xs:dateTime
                )
                ">Dateline date @from/@to/@notBefore/@notAfter must be valid xs:date or xs:dateTime values.</assert>
            <assert test="
                every $attribute in @* 
                satisfies 
                not(matches($attribute, '[A-Z]$'))
                ">Please use timezone offset instead of military time zone (e.g., replace Z with +00:00).</assert>
            <assert test="if (@from and @to) then (@from le @to) else true()">Dateline date @from must come before @to.</assert>
            <assert test="if (@notBefore and @notAfter) then (@notBefore le @notAfter) else true()">Dateline date @notBefore must come before @notAfter.</assert>
        </rule>
    </pattern>
    
    <pattern id="document-date-metadata-checks">
        <title>Document Date Metadata Checks</title>
        <rule context="tei:div[@type eq 'document'][.//tei:dateline[not(ancestor::frus:attachment)]//tei:date[(@from or @notBefore or @when) or (@to or @notAfter or @when)]]">
            <let name="date-min" value="subsequence(.//tei:dateline[not(ancestor::frus:attachment)]//tei:date[@from or @notBefore or @when], 1, 1)/(@from, @notBefore, @when)[. ne ''][1]/string()"/>
            <let name="date-max" value="subsequence(.//tei:dateline[not(ancestor::frus:attachment)]//tei:date[@to or @notAfter or @when], 1, 1)/(@to, @notAfter, @when)[. ne ''][1]/string()"/>
            <let name="timezone" value="xs:dayTimeDuration('PT0H')"/>
            <assert test="@frus:doc-dateTime-min and @frus:doc-dateTime-max" sqf:fix="add-doc-dateTime-attributes">Missing @frus:doc-dateTime-min and @frus:doc-dateTime-max.</assert>
            <assert test="if (@frus:doc-dateTime-min) then frus:normalize-low($date-min, $timezone) eq @frus:doc-dateTime-min else true()" sqf:fix="fix-doc-dateTime-min-attribute">Value of @frus:doc-dateTime-min <value-of select="@frus:doc-dateTime-min"/> does not match normalized value of dateline <value-of select="frus:normalize-low($date-min, $timezone)"/>.</assert>
            <assert test="if (@frus:doc-dateTime-max) then frus:normalize-high($date-max, $timezone) eq @frus:doc-dateTime-max else true()" sqf:fix="fix-doc-dateTime-max-attribute">Value of @frus:doc-dateTime-max <value-of select="@frus:doc-dateTime-max"/> does not match normalized value of dateline <value-of select="frus:normalize-high($date-max, $timezone)"/>.</assert>
            <sqf:fix id="add-doc-dateTime-attributes" role="add">
                <sqf:description>
                    <sqf:title>Add missing @frus:doc-dateTime-min and @frus:doc-dateTime-max attributes</sqf:title>
                </sqf:description>
                <sqf:add target="frus:doc-dateTime-min" node-type="attribute" select="frus:normalize-low($date-min, $timezone)"/>
                <sqf:add target="frus:doc-dateTime-max" node-type="attribute" select="frus:normalize-high($date-max, $timezone)"/>
            </sqf:fix>
            <sqf:fix id="fix-doc-dateTime-min-attribute" role="replace">
                <sqf:description>
                    <sqf:title>Fix @frus:doc-dateTime-min attribute</sqf:title>
                </sqf:description>
                <sqf:replace match="@frus:doc-dateTime-min" target="frus:doc-dateTime-min" node-type="attribute" select="frus:normalize-low($date-min, $timezone)"/>
            </sqf:fix>
            <sqf:fix id="fix-doc-dateTime-max-attribute" role="replace">
                <sqf:description>
                    <sqf:title>Fix @frus:doc-dateTime-max attribute</sqf:title>
                </sqf:description>
                <sqf:replace match="@frus:doc-dateTime-max" target="frus:doc-dateTime-max" node-type="attribute" select="frus:normalize-high($date-max, $timezone)"/>
            </sqf:fix>
        </rule>
    </pattern>
    
    <!-- Functions to normalize dates -->
    
    <xsl:function name="frus:normalize-low">
        <xsl:param name="date"/>
        <xsl:param name="timezone"/>
        <xsl:choose>
            <xsl:when test="$date castable as xs:dateTime">
                <xsl:value-of select="adjust-dateTime-to-timezone(xs:dateTime($date), $timezone)"/>
            </xsl:when>
            <xsl:when test="$date castable as xs:date">
                <xsl:variable name="adjusted-date" select="adjust-date-to-timezone(xs:date($date), $timezone) cast as xs:string"/>
                <xsl:value-of select="substring($adjusted-date, 1, 10) || 'T00:00:00' || substring($adjusted-date, 11)"/>
            </xsl:when>
            <xsl:when test="matches($date, '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$')">
                <xsl:value-of select="adjust-dateTime-to-timezone(xs:dateTime($date || ':00'), $timezone)"/>
            </xsl:when>
            <xsl:when test="matches($date, '^\d{4}-\d{2}$')">
                <xsl:value-of select="adjust-dateTime-to-timezone(xs:dateTime($date || '-01T00:00:00'), $timezone)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="adjust-dateTime-to-timezone(xs:dateTime($date || '-01-01T00:00:00'), $timezone)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="frus:normalize-high">
        <xsl:param name="date"/>
        <xsl:param name="timezone"/>
        <xsl:choose>
            <xsl:when test="$date castable as xs:dateTime">
                <xsl:value-of select="adjust-dateTime-to-timezone(xs:dateTime($date), $timezone)"/>
            </xsl:when>
            <xsl:when test="$date castable as xs:date">
                <xsl:variable name="adjusted-date" select="adjust-date-to-timezone(xs:date($date), $timezone) cast as xs:string"/>
                <xsl:value-of select="substring($adjusted-date, 1, 10) || 'T23:59:59' || substring($adjusted-date, 11)"/>
            </xsl:when>
            <xsl:when test="matches($date, '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$')">
                <xsl:value-of select="adjust-dateTime-to-timezone(xs:dateTime($date || ':59'), $timezone)"/>
            </xsl:when>
            <xsl:when test="matches($date, '^\d{4}-\d{2}$')">
                <xsl:value-of select="adjust-dateTime-to-timezone(xs:dateTime(functx:days-in-month($date || '-01') || 'T23:59:59'), $timezone)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="adjust-dateTime-to-timezone(xs:dateTime($date || '-12-31T23:59:59'), $timezone)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="functx:days-in-month" as="xs:integer?"
        xmlns:functx="http://www.functx.com">
        <xsl:param name="date" as="xs:anyAtomicType?"/>
        
        <xsl:sequence select="
            if (month-from-date(xs:date($date)) = 2 and
            functx:is-leap-year($date))
            then 29
            else
            (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
            [month-from-date(xs:date($date))]
            "/>
        
    </xsl:function>
    
    <xsl:function name="functx:is-leap-year" as="xs:boolean"
        xmlns:functx="http://www.functx.com">
        <xsl:param name="date" as="xs:anyAtomicType?"/>
        
        <xsl:sequence select="
            for $year in xs:integer(substring(string($date),1,4))
            return ($year mod 4 = 0 and
            $year mod 100 != 0) or
            $year mod 400 = 0
            "/>
        
    </xsl:function>
        
</schema>