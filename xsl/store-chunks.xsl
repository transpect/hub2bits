<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xi="http://www.w3.org/2001/XInclude"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:tr="http://transpect.io"
  xmlns:jats="http://jats.nlm.nih.gov"
  version="2.0" exclude-result-prefixes="tr jats xs xi">

  <xsl:import href="http://transpect.io/xslt-util/uri-to-relative-path/xsl/uri-to-relative-path.xsl"/>

  <xsl:param name="include-method" as="xs:string" select="'xinclude'"/>
  <xsl:param name="ft-path-position" select="''" as="xs:string">
    <!-- The n-th last position in the tokenized base URI that will be replaced with $ft-path-replacement.
    Leave as empty string if no full-text export is required -->
  </xsl:param>
  <xsl:param name="ft-path-replacement" select="'ft-out'" as="xs:string"/>
  <xsl:param name="dtd-version" as="xs:string?"/>
  
  <xsl:variable name="ft-path-pos" as="xs:positiveInteger?" 
    select="for $p in $ft-path-position[. castable as xs:positiveInteger]
            return xs:positiveInteger($p)"/>

  <xsl:template match="@* | node()" mode="split export">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@xml:base" mode="split">
    <xsl:param name="export-names" as="document-node(element(export-names))" tunnel="yes"/>
    <xsl:attribute name="{name()}" 
      select="key('export-name-by-genid', generate-id(), $export-names)/@xml:base"/>
    <xsl:if test="$dtd-version">
      <xsl:attribute name="dtd-version" select="$dtd-version"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[parent::*][@xml:base]" mode="split">
    <xsl:param name="export-names" as="document-node(element(export-names))" tunnel="yes"/>
    <xsl:variable name="unique-uri" as="xs:string" 
      select="key('export-name-by-genid', generate-id(), $export-names)/@xml:base"/>
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
    <xsl:variable name="unique-export-names" as="document-node(element(export-names))">
      <xsl:document>
        <export-names>
          <xsl:for-each-group select="$export-roots" group-by="@xml:base">
            <xsl:for-each select="current-group()">
              <xsl:variable name="pos" select="position()" as="xs:integer"/>
              <export-name genid="{generate-id()}">
                <xsl:choose>
                  <xsl:when test="$pos = 1">
                    <xsl:attribute name="xml:base" select="current-grouping-key()"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:attribute name="xml:base"
                      select="replace(current-grouping-key(), '\.xml$', '_' || $pos || '.xml')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </export-name>
            </xsl:for-each>
          </xsl:for-each-group>
        </export-names>
      </xsl:document>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$include-method = 'xinclude'">
        <xsl:next-match>
          <xsl:with-param name="export-names" select="$unique-export-names" tunnel="yes"
            as="document-node(element(export-names))"/>
        </xsl:next-match>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/" mode="toc"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="$export-roots" mode="export">
      <xsl:with-param name="export-names" select="$unique-export-names" tunnel="yes"
         as="document-node(element(export-names))"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:key name="export-name-by-genid" match="export-name" use="@genid"/>

  <xsl:template match="*[@xml:base]" mode="export">
    <xsl:param name="export-names" as="document-node(element(export-names))" tunnel="yes"/>
    <xsl:variable name="unique-uri" as="xs:string" 
      select="key('export-name-by-genid', generate-id(), $export-names)/@xml:base"/>
    <xsl:result-document href="{$unique-uri}">
      <xsl:copy>
        <xsl:apply-templates select="@*, node()" mode="split"/>
      </xsl:copy>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:variable name="root" as="document-node(element(*))" select="/"/>

  <xsl:key name="by-id" match="*[@id]" use="@id"/>

  <xsl:template match="@rid[not($include-method = 'xinclude')]" mode="split" as="item()*">
    <xsl:param name="export-names" as="document-node(element(export-names))" tunnel="yes"/>
    <xsl:variable name="base" 
      select="key('export-name-by-genid', generate-id(ancestor::*[@xml:base][1]), $export-names)/@xml:base" as="xs:string"/>
    <xsl:variable name="targets" as="xs:string+">
      <xsl:for-each select="tokenize(., '\s+', 's')">
        <xsl:variable name="target-base" 
          select="for $t in key('by-id', ., $root)
                  return key('export-name-by-genid', generate-id($t/ancestor-or-self::*[@xml:base][1]), $export-names)/@xml:base"
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
            <target rid="{substring-after(., '#')}"/>
          </xsl:for-each>
        </group>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:if test="count($grouped) gt 1">
      <xsl:message select="'Link to multiple output files: ', $grouped" terminate="yes"/>  
    </xsl:if>
    <xsl:for-each select="$grouped">
      <xsl:attribute name="rid" separator=" ">
        <xsl:for-each select="target">
          <xsl:sequence select="../@target-file || '#' || @rid"/>
        </xsl:for-each>
      </xsl:attribute>
      <xsl:apply-templates mode="alt"
        select="key('by-id', target[1]/@rid, $root)/ancestor-or-self::*[@xml:base][1]"/>
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
  
  <xsl:template match="index-term | fn" mode="alt toc"/>

  <xsl:template match="*" mode="alt">
    <xsl:message select="'store-chunks.xsl, mode ''alt'': Please support ', name()"/>
  </xsl:template>
  
  <xsl:template match="sub | target" mode="alt"/>

  <xsl:template match="book-part" mode="alt">
    <xsl:attribute name="alt" separator="">
      <xsl:value-of select="@book-part-type"/>
      <xsl:text xml:space="preserve"> “</xsl:text>
      <xsl:apply-templates select="book-part-meta/title-group/title" mode="#current"/>
      <xsl:text>”</xsl:text>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="sec" mode="alt">
    <xsl:apply-templates select="title" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="title" mode="alt">
    <xsl:attribute name="alt" separator="">
      <xsl:text xml:space="preserve">“</xsl:text>
      <xsl:apply-templates mode="#current"/>
      <xsl:text>”</xsl:text>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="p" mode="alt">
    <xsl:attribute name="alt" separator="">
      <xsl:text xml:space="preserve">“</xsl:text>
      <xsl:variable name="text" as="xs:string">
        <xsl:apply-templates mode="#current"/>  
      </xsl:variable>
      <xsl:sequence select="substring($text, 1, 30)"/>
      <xsl:text>…”</xsl:text>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="/" mode="toc">
    <toc>
      <xsl:apply-templates mode="#current"/>
    </toc>
  </xsl:template>
  
  <xsl:template match="*[@xml:base]" mode="toc">
    <toc-entry>
      <xsl:apply-templates select="@content-type | @book-part-type | @sec-type" mode="#current"/>
      <xsl:apply-templates select="*[1]/descendant-or-self::title |
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