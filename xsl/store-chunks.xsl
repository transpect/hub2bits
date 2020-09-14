<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xi="http://www.w3.org/2001/XInclude"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:tr="http://transpect.io"
  xmlns:jats="http://jats.nlm.nih.gov"
  version="3.0" exclude-result-prefixes="tr jats xs xi">

  <xsl:import href="http://transpect.io/xslt-util/uri-to-relative-path/xsl/uri-to-relative-path.xsl"/>

  <xsl:param name="include-method" as="xs:string" select="'xinclude'"/>
  <xsl:param name="ft-path-position" select="''" as="xs:string">
    <!-- The n-th (or n-th last if negative) position in the tokenized base URI 
      will be replaced with $ft-path-replacement. Leave as empty string if no 
      full-text export is required -->
  </xsl:param>
  <xsl:param name="ft-path-replacement" select="'ft-out'" as="xs:string"/>
  <xsl:param name="dtd-version" as="xs:string?"/>
  
  <xsl:variable name="ft-path-pos" as="xs:integer?" 
    select="for $p in $ft-path-position[. castable as xs:positiveInteger]
            return xs:integer($p)"/>

  <xsl:template match="@* | node()" mode="split export xlink-href">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@xml:base" mode="split">
    <xsl:param name="export-file-names" as="document-node(element(export-file-names))" tunnel="yes"/>
    <xsl:attribute name="{name()}" 
      select="key('export-name-by-genid', generate-id(), $export-file-names)/@xml:base"/>
    <xsl:if test="$dtd-version">
      <xsl:attribute name="dtd-version" select="$dtd-version"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[parent::*][@xml:base]" mode="split">
    <xsl:param name="export-file-names" as="document-node(element(export-file-names))" tunnel="yes"/>
    <xsl:variable name="unique-uri" as="xs:string" 
      select="key('export-name-by-genid', generate-id(), $export-file-names)/@xml:base"/>
    <xsl:choose>
      <xsl:when test="$include-method = 'xinclude'">
        <xsl:element name="xi:include">
          <xsl:attribute name="href" select="jats:relative-link(/*/@xml:base, $unique-uri, ())"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="related-object">
          <xsl:attribute name="xlink:href" select="$unique-uri"/>
          <xsl:attribute name="content-type" select="@sec-type | @book-part-type"/>
          <xsl:variable name="title" as="element(title)">
            <xsl:apply-templates select="(.//title)[1]" mode="toc"/>
          </xsl:variable>
          <chapter-title>
            <xsl:sequence select="$title/node()"/>  
          </chapter-title>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template mode="split" match="/*">
    <xsl:variable name="export-roots" as="element(*)*" select="descendant-or-self::*[@xml:base]"/>
    <xsl:variable name="unique-export-names" as="document-node(element(export-file-names))">
      <xsl:document>
        <export-file-names>
          <xsl:for-each-group select="$export-roots" group-by="@xml:base">
            <xsl:for-each select="current-group()">
              <xsl:variable name="pos" select="position()" as="xs:integer"/>
              <export-name genid="{generate-id()}">
                <xsl:choose>
                  <xsl:when test="$pos = 1">
                    <!-- This is just a workaround for an issue that occurs when invoking this from XProc.
                      Saxon thinks that the top-level element’s base URI is the URI that the document was 
                      read from. Therefore it refuses to “store” it to the same location. We avoid this by 
                    duplicating the last slash in the URI. -->
                    <xsl:attribute name="xml:base" 
                      select="replace(current-grouping-key(), '^(.+/)', '$1/')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:attribute name="xml:base"
                      select="replace(current-grouping-key(), '\.xml$', '_' || $pos || '.xml')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </export-name>
            </xsl:for-each>
          </xsl:for-each-group>
        </export-file-names>
      </xsl:document>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$include-method = 'xinclude'">
        <xsl:next-match>
          <xsl:with-param name="export-file-names" select="$unique-export-names" tunnel="yes"
            as="document-node(element(export-file-names))"/>
        </xsl:next-match>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/" mode="toc">
          <xsl:with-param name="export-file-names" select="$unique-export-names" tunnel="yes"
            as="document-node(element(export-file-names))"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:result-document href="links-adjusted.xml">
      <xsl:apply-templates select="." mode="xlink-href">
        <xsl:with-param name="export-file-names" select="$unique-export-names" tunnel="yes"
          as="document-node(element(export-file-names))"/>
      </xsl:apply-templates>  
    </xsl:result-document>
    <xsl:apply-templates select="$export-roots" mode="export">
      <xsl:with-param name="export-file-names" select="$unique-export-names" tunnel="yes"
         as="document-node(element(export-file-names))"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:key name="export-name-by-genid" match="export-name" use="@genid"/>

  <xsl:template match="*[@xml:base]" mode="export">
    <xsl:param name="export-file-names" as="document-node(element(export-file-names))" tunnel="yes"/>
    <xsl:variable name="unique-uri" as="xs:string" 
      select="key('export-name-by-genid', generate-id(), $export-file-names)/@xml:base"/>
    <xsl:result-document href="{$unique-uri}">
      <xsl:copy>
        <xsl:apply-templates select="@*, node()" mode="split"/>
      </xsl:copy>
    </xsl:result-document>  
  </xsl:template>
  
  <xsl:variable name="root" as="document-node(element(*))" select="/"/>

  <xsl:key name="by-id" match="*[@id]" use="@id"/>

  <xsl:template match="xref[@ref-type='bibr'][@rid]" mode="split xlink-href" priority="1">
    <xsl:variable name="context" as="element(xref)" select="."/>
    <xsl:variable name="xlink-href" as="attribute()*">
      <xsl:apply-templates select="@rid" mode="xlink-href"/>
    </xsl:variable>
    <xsl:text>[</xsl:text>
    <xsl:for-each select="tokenize($xlink-href/self::attribute(xlink:href))[normalize-space()]">
      <xsl:variable name="current" select="." as="xs:string"/>
      <xsl:variable name="rid" as="xs:string" select="replace($current, '^.*#', '')"/>
      <xsl:copy select="$context">
        <xsl:copy-of select="@*"/>
        <xsl:attribute name="rid" select="$rid"/>
        <xsl:apply-templates select="key('by-id', $rid, $root)" mode="alt"/>
        <ext-link>
          <xsl:attribute name="xlink:href" select="$current"/>
          <xsl:apply-templates select="$context" mode="link-text">
            <xsl:with-param name="fragid" select="$rid"/>
          </xsl:apply-templates>
        </ext-link>
      </xsl:copy>
      <xsl:if test="not(position() = last())">
        <xsl:text>,</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:text>]</xsl:text>
  </xsl:template>
    
  <xsl:template match="xref[@rid]" mode="split xlink-href">
    <xsl:variable name="context" as="element(xref)" select="."/>
    <xsl:copy>
      <xsl:apply-templates select="@* except @rid" mode="#current"/>
      <xsl:apply-templates select="key('by-id', @rid)" mode="ref-type"/>
      <xsl:copy-of select="@rid, @ref-type"/>
      <xsl:variable name="xlink-href" as="attribute()*">
        <xsl:apply-templates select="@rid" mode="xlink-href"/>
      </xsl:variable>
      <xsl:sequence select="$xlink-href/self::attribute(alt)[normalize-space()]"/>
      <xsl:choose>
        <xsl:when test="matches($xlink-href/self::attribute(xlink:href), '\w#\w')">
          <xsl:for-each select="tokenize($xlink-href/self::attribute(xlink:href))[normalize-space()]">
            <ext-link>
              <xsl:attribute name="xlink:href" select="."/>
              <xsl:apply-templates select="$context" mode="link-text">
                <xsl:with-param name="fragid" select="replace(., '^.*#', '')"/>
              </xsl:apply-templates>
            </ext-link>
            <xsl:if test="not(position() = last())">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="matches($xlink-href/self::attribute(xlink:href), '\w')">
          <xsl:for-each select="tokenize($xlink-href/self::attribute(xlink:href))[normalize-space()]">
            <ext-link>
              <xsl:attribute name="xlink:href" select="."/>
            </ext-link>
            <xsl:if test="not(position() = last())">
              <xsl:text>,</xsl:text>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$xlink-href/self::attribute(rid)"/>
          <xsl:apply-templates mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*" mode="ref-type"/>
  
  <xsl:template match="front-matter-part" mode="ref-type">
    <xsl:attribute name="ref-type" select="local-name()"/>
  </xsl:template>
  
  <xsl:template match="xref[node()]" mode="link-text" priority="1">
    <xsl:apply-templates mode="split"/>
  </xsl:template>
  
  <xsl:template match="xref[@ref-type = 'bibr']" mode="link-text">
    <xsl:param name="fragid" as="xs:string?"/>
    <xsl:variable name="ref" as="element(ref)?" select="key('by-id', $fragid, $root)"/>
    <xsl:value-of select="index-of($ref/../ref/generate-id(), $ref/generate-id())"/>
  </xsl:template>
  
  <xsl:template match="xref[@ref-type = 'table-fn']/@rid" mode="xlink-href" priority="1">
    <xsl:variable name="fn" as="element(*)?" select="key('by-id', ., $root)"/>
    <xsl:apply-templates select="$fn" mode="alt"/>
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <xsl:template match="def-list[@list-type = 'tablefootnotes']/def-item" mode="alt">
    <xsl:variable name="alt" as="item()*">
      <xsl:apply-templates select="def/p/node()" mode="alt"/>
    </xsl:variable>
    <xsl:attribute name="alt" select="normalize-space(string-join($alt, ''))"/>
  </xsl:template>

  <xsl:template match="def-list[@list-type = 'tablefootnotes']/def-item/def/p/text()[last()]" mode="alt">
    <xsl:value-of select="replace(., '\p{P}\s*$', '')"/>
  </xsl:template>

  <xsl:template match="xref" mode="alt">
    <xsl:value-of>
      <xsl:apply-templates select="." mode="xlink-href"/>
    </xsl:value-of>
  </xsl:template>
  
  <xsl:template match="xref[@rid]" mode="alt">
    <xsl:apply-templates select="key('by-id', @rid)" mode="#current"/>
  </xsl:template>

  <xsl:template match="xref/@rid[not($include-method = 'xinclude')]" mode="xlink-href" as="attribute()*">
    <xsl:param name="export-file-names" as="document-node(element(export-file-names))" tunnel="yes"/>
    <xsl:variable name="base" 
      select="key('export-name-by-genid', generate-id(ancestor::*[@xml:base][1]), $export-file-names)/@xml:base" as="xs:string"/>
    <xsl:variable name="targets" as="xs:string+">
      <xsl:for-each select="tokenize(., '\s+', 's')">
        <xsl:variable name="target-base" 
          select="for $t in key('by-id', ., $root)
                  return key('export-name-by-genid', generate-id($t/ancestor-or-self::*[@xml:base][1]), $export-file-names)/@xml:base"
          as="xs:string?"/>
        <xsl:choose>
          <xsl:when test="$target-base and not($base = $target-base)">
            <xsl:sequence select="jats:relative-link($base, $target-base, .)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="grouped" as="element(group)+">
      <xsl:for-each-group select="$targets" group-by="substring-before(., '#')">
        <group target-file="{current-grouping-key()}">
          <xsl:for-each select="current-group()">
            <target rid="{if (contains(., '#')) then substring-after(., '#') else .}"/>
          </xsl:for-each>
        </group>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:if test="count($grouped) gt 1">
      <xsl:message select="'Link to multiple output files: ', $grouped" terminate="yes"/>  
    </xsl:if>
    <xsl:for-each select="$grouped">
      <xsl:choose>
        <xsl:when test="@target-file = ''">
          <xsl:attribute name="rid" separator=" ">
            <xsl:for-each select="target">
              <xsl:sequence select="@rid"/>
            </xsl:for-each>
          </xsl:attribute>
          <xsl:apply-templates mode="alt"
            select="for $elt in key('by-id', target[1]/@rid, $root)/ancestor-or-self::*[title] 
                    return ($elt/titleabbrev, $elt/title)[1]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="xlink:href" separator=" ">
            <xsl:for-each select="target">
              <!-- [empty(key('by-id', ., $root)/@xml:base)] should create a link without fragment identifier for 
                top-level elements -->
              <xsl:sequence select="string-join((../@target-file, @rid[empty(key('by-id', ., $root)/@xml:base)]), '#')"/>
            </xsl:for-each>
          </xsl:attribute>
          <xsl:apply-templates mode="alt"
            select="key('by-id', target[1]/@rid, $root)/ancestor-or-self::*[@xml:base][1]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:function name="jats:relative-link" as="xs:string">
    <xsl:param name="base-uri" as="xs:string"/>
    <xsl:param name="target-uri" as="xs:string"/>
    <xsl:param name="rid" as="xs:string?"/>
    <xsl:variable name="base-dir" select="replace($base-uri, '^(.+)/.+$', '$1')" as="xs:string?"/>
    <xsl:variable name="relative" as="xs:string" select="tr:uri-to-relative-path($base-dir, $target-uri)"/>
    <xsl:sequence select="string-join(($relative, $rid), '#')"/>
  </xsl:function>
  
  <xsl:template match="index-term | fn | index-term-range-end | target" mode="alt toc"/>

  <xsl:template match="*" mode="alt">
    <xsl:message select="'store-chunks.xsl, mode ''alt'': Please support ', name(), ' ID: ', @id" terminate="yes"/>
  </xsl:template>
  
  <xsl:template match="mixed-citation | ext-link | sc | sub | sup | italic | bold 
    | named-content[not(@content-type = 'print')]" mode="alt">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="break" mode="alt">
    <xsl:text xml:space="preserve"> </xsl:text>
  </xsl:template>
  
  <xsl:template match="ref" mode="alt" as="attribute(alt)">
    <xsl:variable name="tmp" as="item()*">
      <xsl:apply-templates select="mixed-citation/node()" mode="#current"/>
    </xsl:variable>   
    <xsl:attribute name="alt" select="normalize-space(string-join($tmp))"/>
  </xsl:template>
  
  <xsl:template match="front-matter-part | book-part" mode="alt">
    <xsl:attribute name="alt" separator="">
<!--      <xsl:value-of select="@book-part-type"/>
      <xsl:text xml:space="preserve"> </xsl:text>-->
      <xsl:apply-templates select="book-part-meta/title-group/title" mode="#current"/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="sec" mode="alt">
    <xsl:apply-templates select="title" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="sec/table-wrap[empty(caption/title | label)]" mode="alt">
    <xsl:apply-templates select="../title" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="title" mode="alt">
    <xsl:variable name="result" as="node()*">
      <xsl:apply-templates mode="#current"/>
    </xsl:variable>
    <xsl:variable name="result-as-string" as="xs:string" select="normalize-space(string-join($result))"/>
    <xsl:attribute name="alt" separator="">
      <xsl:if test="not(starts-with($result-as-string, '“'))">
        <xsl:text>“</xsl:text>
      </xsl:if>
      <xsl:sequence select="$result"/>
      <xsl:if test="not(starts-with($result-as-string, '“'))">
        <xsl:text>”</xsl:text>
      </xsl:if>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="p" mode="alt">
    <xsl:attribute name="alt" separator="">
      <xsl:text xml:space="preserve">“</xsl:text>
      <xsl:variable name="text" as="xs:string*">
        <xsl:apply-templates mode="#current"/>  
      </xsl:variable>
      <xsl:sequence select="substring(string-join($text), 1, 30)"/>
      <xsl:text>…”</xsl:text>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="/" mode="toc">
    <xsl:param name="export-file-names" as="document-node(element(export-file-names))" tunnel="yes"/>
    <toc>
      <xsl:apply-templates mode="#current"/>
      <!--<xsl:sequence select="$export-file-names/*"/>-->
    </toc>
  </xsl:template>
  
  <xsl:template match="*[@xml:base]" mode="toc">
    <toc-entry>
      <xsl:apply-templates select="@content-type | @book-part-type | @sec-type" mode="#current"/>
      <xsl:apply-templates select="*[empty(self::sec-meta)][1]/descendant-or-self::title |
                                   *[1]/descendant-or-self::book-title" mode="#current"/>
      <ext-link>
        <xsl:attribute name="xlink:href" select="jats:relative-link(/*/@xml:base, @xml:base, ())"/>
      </ext-link>
      <xsl:apply-templates select="descendant::*[@xml:base][ancestor::*[@xml:base][1] is current()]" mode="#current"/>
    </toc-entry>
  </xsl:template>
  
  <xsl:template match="title | book-title" mode="toc">
    <xsl:apply-templates select="preceding-sibling::label" mode="#current"/>
    <title>
      <xsl:apply-templates mode="#current"/>
    </title>
    <xsl:apply-templates select="following-sibling::subtitle" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="label | subtitle" mode="toc">
    <xsl:copy>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@book-part-type | @content-type | @sec-type" mode="toc">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>
  
  <xsl:template match="text()" mode="toc"/>
  <xsl:template match="book-title//text() | title//text() | label//text()" mode="toc">
    <xsl:copy/>
  </xsl:template>
</xsl:stylesheet>