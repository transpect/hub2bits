<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:jats="http://jats.nlm.nih.gov"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  exclude-result-prefixes="css dbk jats xs xlink"
  version="2.0">

  <xsl:import href="http://transpect.le-tex.de/hub2html/xsl/css-atts2wrap.xsl"/>
  
  <xsl:param name="srcpaths" select="'no'"/>

  <xsl:variable name="dtd-version-att" as="attribute(dtd-version)">
    <xsl:attribute name="dtd-version" select="'0.2-variant Hogrefe Book Tag Set (hobots) 0.1'" />
  </xsl:variable>

  <xsl:template match="* | @*" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/*" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:namespace name="css" select="'http://www.w3.org/1996/css'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:key name="by-id" match="*[@id]" use="@id"/>

  <!-- This anchor has already given its ID to someone else, but we've been
    too lazy to remove this anchor in the first run. -->
  <xsl:template match="target[key('by-id', @id)/local-name() != 'target']" mode="clean-up"/>

  <xsl:template match="styled-content[every $att in @* satisfies $att/self::attribute(srcpath)]" mode="clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="*" mode="default" priority="-1">
    <xsl:message>Unhandled: <xsl:apply-templates select="." mode="unhandled"/>
    </xsl:message>
    <xsl:copy copy-namespaces="no">
      <xsl:call-template name="css:content"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@*" mode="default" priority="-1.5">
    <xsl:copy/>
    <xsl:message>Unhandled attr: <xsl:apply-templates select="." mode="unhandled"/>
    </xsl:message>
  </xsl:template>
  
  <xsl:template match="*" mode="unhandled" >
    <xsl:message select="concat(name(), '  ', substring(normalize-space(.),1,40))" /> 
    <xsl:apply-templates select="@*" mode="#current" />
  </xsl:template>
  
  <xsl:template match="@*" mode="unhandled" >
    <xsl:message select="concat('  ', name(), '=', .)" /> 
  </xsl:template>
  

  <!-- DEFAULT ATTRIBUTE HANDLING -->

  <xsl:template match="@xml:id" mode="default">
    <xsl:attribute name="id" select="."/>
  </xsl:template>

  <xsl:template match="@role" mode="default">
    <xsl:attribute name="content-type" select="."/>
  </xsl:template>

  <xsl:template match="@linkend | @linkends" mode="default">
    <xsl:attribute name="rid" select="."/>
  </xsl:template>

  <xsl:template match="@remap" mode="default"/>

  <xsl:template match="@css:*" mode="default">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="@xlink:href" mode="default">
    <xsl:copy/>
  </xsl:template>  
  
  <xsl:template match="@xml:lang" mode="default">
    <xsl:copy/>
  </xsl:template>  
  
  <xsl:template match="@srcpath[$srcpaths = 'yes']" mode="default">
    <xsl:copy/>
  </xsl:template>  

  <xsl:template match="@srcpath[not($srcpaths = 'yes')]" mode="default"/>
  
  <!-- STRUCTURE -->
  
  <xsl:function name="jats:matter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="name" select="$elt/local-name()" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$name = 'info'"><xsl:sequence select="''"/></xsl:when>
      <xsl:when test="$name = ('toc', 'preface')"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$name = ('part', 'chapter')"><xsl:sequence select="'book-body'"/></xsl:when>
      <xsl:when test="$name = ('appendix')"><xsl:sequence select="'book-back'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'dark-matter'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="dbk:book | dbk:hub[dbk:chapter] | dbk:hub[dbk:part]" mode="default">
    <book>
      <xsl:namespace name="css" select="'http://www.w3.org/1996/css'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:sequence select="$dtd-version-att"/>
      <book-meta>
        <book-title-group>
          <xsl:apply-templates select="dbk:info/dbk:title | dbk:title" mode="#current"/>
        </book-title-group>
        <custom-meta-group>
          <xsl:copy-of select="dbk:info/css:rules"/>  
        </custom-meta-group>
      </book-meta>
      <xsl:for-each-group select="*" group-adjacent="jats:matter(.)">
        <xsl:if test="current-grouping-key() ne ''">
          <xsl:element name="{current-grouping-key()}">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:element>
        </xsl:if>
      </xsl:for-each-group>
    </book>
  </xsl:template>
  
  <xsl:template match="dbk:toc" mode="default">
    <toc>
      <xsl:apply-templates select="." mode="toc-depth"/>
      <xsl:call-template name="css:content"/>
    </toc>
  </xsl:template>

  <xsl:template match="dbk:toc/dbk:title" mode="default" priority="2">
    <title-group>
      <xsl:next-match/>
    </title-group>
  </xsl:template>
  

  <xsl:template match="dbk:toc" mode="toc-depth">
    <xsl:attribute name="depth" select="'3'"/>
  </xsl:template>

  <xsl:template match="dbk:section" mode="default">
    <sec><xsl:call-template name="css:content"/></sec>
  </xsl:template>

  <xsl:template match="dbk:appendix" mode="default">
    <app><xsl:call-template name="css:content"/></app>
  </xsl:template>
  
  <xsl:function name="jats:book-part" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:part or $elt/self::dbk:chapter"><xsl:sequence select="'book-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface"><xsl:sequence select="'preface'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'unknown-book-part'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="jats:book-part-body" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:part or $elt/self::dbk:chapter"><xsl:sequence select="'body'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface"><xsl:sequence select="'named-book-part-body'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="concat('unknown-book-part-body_', $elt/name())"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="dbk:part | dbk:chapter | dbk:preface" mode="default">
    <xsl:variable name="elt-name" as="xs:string" select="jats:book-part(.)"/>
    <xsl:element name="{$elt-name}">
      <xsl:call-template name="css:other-atts"/>
      <xsl:sequence select="$dtd-version-att"/>
      <xsl:if test="$elt-name eq 'book-part'">
        <xsl:attribute name="book-part-type" select="local-name()"/>
      </xsl:if>
      <xsl:variable name="context" select="." as="element(*)"/>
      <xsl:for-each-group select="*" group-adjacent="boolean(self::dbk:title or self::dbk:info)">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
              <book-part-meta>
                <xsl:call-template name="title-info">
                  <xsl:with-param name="elts" select="current-group()/(self::dbk:title union self::dbk:info/*)"/>
                </xsl:call-template>
              </book-part-meta>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="{jats:book-part-body($context)}">
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>

  <xsl:template match="dbk:preface/@role" mode="default">
    <xsl:attribute name="book-part-type" select="."/>
  </xsl:template>
  
  <!-- METADATA -->

  <xsl:function name="jats:meta-component" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:title or $elt/self::dbk:subtitle"><xsl:sequence select="'title-group'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:author"><xsl:sequence select="'contrib-group'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:abstract"><xsl:sequence select="'abstract'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="concat('unknown-meta_', $elt/name())"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template name="title-info" as="element(*)+">
    <xsl:param name="elts" as="element(*)+"/>
    <xsl:for-each-group select="$elts" group-by="jats:meta-component(.)">
      <xsl:choose>
        <xsl:when test="current-grouping-key() = 'abstract'">
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="{current-grouping-key()}">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="dbk:info" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:abstract" mode="default">
    <abstract><xsl:call-template name="css:content"/></abstract>
  </xsl:template>

  <xsl:template match="dbk:author" mode="default">
    <contrib contrib-type="{local-name()}"><xsl:call-template name="css:content"/></contrib>
  </xsl:template>
  
  <xsl:template match="dbk:personname" mode="default">
    <string-name><xsl:call-template name="css:content"/></string-name>
  </xsl:template>
  <!-- BLOCK -->
  
  <xsl:template match="dbk:title" mode="default">
    <title><xsl:call-template name="css:content"/></title>
  </xsl:template>

  <xsl:template match="dbk:title[dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')]]" mode="default">
    <label>
      <xsl:apply-templates mode="#current" select="dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')]/node()"/>
    </label>
    <title>
      <xsl:apply-templates mode="#current"
        select="node() except (dbk:phrase[@role = ('hub:caption-number', 'hub:identifier')] | dbk:tab)"/>
    </title>
  </xsl:template>

  <xsl:template match="dbk:para" mode="default">
    <p><xsl:call-template name="css:content"/></p>
  </xsl:template>
  
  <!-- INLINE -->
  
  <xsl:template match="dbk:phrase" mode="default">
    <styled-content><xsl:call-template name="css:content"/></styled-content>
  </xsl:template>

  <xsl:template match="dbk:phrase/@role" mode="default">
    <xsl:attribute name="style-type" select="."/>
  </xsl:template>

  <xsl:template match="dbk:link[@linkend, @linkends]" mode="default">
    <xref><xsl:call-template name="css:content"/></xref>
  </xsl:template>
  
  <xsl:template match="dbk:link[@xlink:href]" mode="default">
    <ext-link><xsl:call-template name="css:content"/></ext-link>
  </xsl:template>

  <xsl:template match="dbk:anchor" mode="default">
    <target><xsl:call-template name="css:content"/></target>
  </xsl:template>

  <xsl:template match="dbk:br" mode="default">
    <break/>
  </xsl:template>
  
  <!-- FOOTNOTES -->
  
  <xsl:template match="dbk:footnote" mode="default">
    <fn><xsl:call-template name="css:content"/></fn>
  </xsl:template>
  
  
  <!-- BOXES -->
  
  <xsl:function name="jats:box-type" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:apply-templates select="$elt" mode="box-type"/>
  </xsl:function>

  <!-- override these templates in your customization so that there remains a single text node
       that gives the box type -->
  
  <xsl:template match="*" mode="box-type">
    <xsl:apply-templates select="@*, *" mode="#current"/>
  </xsl:template>

  <xsl:template match="@*" mode="box-type"/>
  
  <!-- TABLES -->
  
  <!-- todo: group with table footnotes -->
  
  <xsl:template match="dbk:title[parent::table]" mode="default">
    <caption>
      <xsl:call-template name="css:content"/>
    </caption>
  </xsl:template>
  
  <xsl:template match="dbk:row" mode="default">
    <tr>
      <xsl:call-template name="css:content"/>
    </tr>
  </xsl:template>
  
  <xsl:template match="dbk:tgroup" mode="default">
    <xsl:call-template name="css:content"/>
  </xsl:template>
  
  <xsl:template match="dbk:tgroup/@cols" mode="default"/>
  
  <xsl:template match="dbk:tbody" mode="default">
    <tbody>
      <xsl:call-template name="css:content"/>
    </tbody>
  </xsl:template>
  
  <xsl:template match="dbk:thead" mode="default">
    <thead>
      <xsl:call-template name="css:content"/>
    </thead>
  </xsl:template>
  
  <xsl:template match="dbk:entry" mode="default">
    <xsl:element name="{if (ancestor::dbk:thead) then 'th' else 'td'}">
      <xsl:call-template name="css:content"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="dbk:entry/@namest" mode="default">
    <xsl:attribute name="colspan" select="number(replace(../@nameend, 'c(ol)?', '')) - number(replace(., 'c(ol)?', '')) + 1"/>
  </xsl:template>
  
  <xsl:template match="dbk:entry/@morerows" mode="default">
    <xsl:if test="xs:integer(.) gt 1">
      <xsl:attribute name="rowspan" select=". + 1"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="dbk:table" mode="default" priority="2">
    <table-wrap>
      <xsl:call-template name="css:other-atts"/>
      <label>
        <xsl:apply-templates mode="#current" select="dbk:title/dbk:phrase[@role eq 'hub:caption-number']"/>
      </label>
      <caption>
        <title>
          <xsl:apply-templates mode="#current" 
            select="dbk:title/(node() except (dbk:phrase[@role eq 'hub:caption-number'] | dbk:tab))"/>  
        </title>
      </caption>
      <xsl:next-match/>
    </table-wrap>
  </xsl:template>
  
  <xsl:template match="dbk:informaltable | dbk:table" mode="default">
    <table>
      <xsl:for-each select="self::dbk:informaltable">
        <xsl:call-template name="css:other-atts"/>
      </xsl:for-each>
      <xsl:choose>
        <xsl:when test="exists(dbk:tgroup/*/dbk:row)">
          <xsl:apply-templates select="* except dbk:title" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <HTMLTABLE_TODO/>
          <xsl:apply-templates mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </table>
  </xsl:template>
  
  <xsl:template match="dbk:colspec | @colname | @nameend" mode="default"/>
  
  <!-- BIBLIOGRAPHY -->
  
  <xsl:template match="dbk:bibliography" mode="default">
    <ref-list><xsl:call-template name="css:content"/></ref-list>
  </xsl:template>

  <xsl:template match="dbk:biblioentry" mode="default">
    <ref><xsl:call-template name="css:content"/></ref>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomisc" mode="default">
    <mixed-citation><xsl:call-template name="css:content"/></mixed-citation>
  </xsl:template>
  

</xsl:stylesheet>