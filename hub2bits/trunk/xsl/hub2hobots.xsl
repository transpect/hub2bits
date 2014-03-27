<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:jats="http://jats.nlm.nih.gov"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:functx="http://www.functx.com" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  exclude-result-prefixes="css dbk functx jats xs xlink"
  version="2.0">

  <xsl:import href="http://transpect.le-tex.de/hub2html/xsl/css-atts2wrap.xsl"/>
  
  <xsl:param name="srcpaths" select="'no'"/>
  <xsl:param name="work-path"/>

  <xsl:param name="css:wrap-namespace" as="xs:string" select="''"/> 
  
  <xsl:variable name="dtd-version-att" as="attribute(dtd-version)">
    <xsl:attribute name="dtd-version" select="'1.0-variant Hogrefe Book Tag Set (hobots) 1.0'" />
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
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  

  <xsl:key name="by-id" match="*[@id]" use="@id"/>

  <!-- This anchor has already given its ID to someone else, but we've been
    too lazy to remove this anchor in the first run. -->
  <xsl:template match="target[key('by-id', @id)/local-name() != 'target']" mode="clean-up"/>

  <xsl:template match="styled-content[every $att in @* satisfies $att/self::attribute(srcpath)]" mode="clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="styled-content[. = '']" mode="clean-up" priority="2"/>

  <xsl:template match="th/p[bold][every $n in node() satisfies ($n/self::bold)]" mode="clean-up">
    <xsl:apply-templates select="bold/node()" mode="#current"/>
  </xsl:template>

  <xsl:template match="th[p][count(p) eq 1][not(p/bold)]" mode="clean-up">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="css:font-weight" select="'normal'"/>
      <xsl:apply-templates select="p/node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="table[count(thead) gt 1]" mode="clean-up">
    <xsl:variable name="context" select="." as="element(table)"/>
    <xsl:for-each-group select="*" group-starting-with="thead">
      <xsl:for-each select="$context">
        <xsl:copy>
          <xsl:apply-templates select="@*, current-group()" mode="#current"/>
        </xsl:copy>
      </xsl:for-each>
    </xsl:for-each-group>
  </xsl:template>
  

  <xsl:template match="body[not(following-sibling::back)][ref-list]" mode="clean-up">
    <xsl:next-match/>
    <back>
      <xsl:for-each select="ref-list">
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates select="@*, node()" mode="#current"/>
        </xsl:copy>
      </xsl:for-each>
    </back>
  </xsl:template>
  <xsl:template match="body[not(following-sibling::back)]/ref-list" mode="clean-up"/>
  
  <xsl:template match="p[boxed-text][every $n in node() satisfies ($n/self::boxed-text)]" mode="clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <!-- not permitted by schema: -->
  <xsl:template match="sub/@content-type | sup/@content-type" mode="clean-up"/>

  <xsl:template match="dbk:tab | dbk:tabs" mode="clean-up"/>

  <!-- Dissolve styled content whose css atts all went to the attic.
       Will lose srcpath attributes though. Solution: Adapt the srcpath message rendering mechanism 
       so that it uses ancestor paths if it doesn’t find an immediate matching element. -->
  <xsl:template match="styled-content[@style-type]
                                     [every $att in @* satisfies (name($att) = ('style-type', 'xml:id', 'srcpath'))]"
                mode="clean-up">
    <xsl:param name="root" as="document-node(element(*))" select="root()" tunnel="yes"/>
    <xsl:choose>
      <!-- This condition would usually have appeared as a predicate of the matching pattern.
           Since we might process temporary trees in the adaptions, we need to be able to
           explicitly pass a root node to the key function. -->
      <xsl:when test="every $att in key('jats:style-by-type', @style-type, $root)/@* 
                      satisfies (name($att) = ('name', 'native-name', 'layout-type'))">
        <xsl:apply-templates mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:key name="jats:style-by-type" match="css:rule" use="@name" />
  
  <xsl:template match="*" mode="default" priority="-1">
    <xsl:message>hub2hobots: unhandled in mode default: <xsl:apply-templates select="." mode="css:unhandled"/>
    </xsl:message>
    <xsl:copy copy-namespaces="no">
      <xsl:call-template name="css:content"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@*" mode="default" priority="-1.5">
    <xsl:copy/>
    <xsl:message>hub2hobots: attr unhandled in mode default: <xsl:apply-templates select="." mode="css:unhandled"/>
    </xsl:message>
  </xsl:template>

  <!-- MOVE WRAP ATTS (italic, bold, underline) TO CSS RULE ATTIC -->
  
  <xsl:template match="css:rule[$css:wrap-content-with-elements-from-mappable-style-attributes]" mode="default">
    <xsl:call-template name="css:move-to-attic">
      <xsl:with-param name="atts" select="@*[css:map-att-to-elt(., key('css:styled-content', ../@name)[1])]"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="css:rule[$css:wrap-content-with-elements-from-mappable-style-attributes]
                               [not(key('css:styled-content', @name))]" mode="default" priority="2">
    <xsl:comment>css:rule
    <xsl:for-each select="@*">
      <xsl:sequence select="concat(name(), '=&quot;', ., '&quot;&#xa;')"/>
    </xsl:for-each>
    </xsl:comment>
  </xsl:template>
  
  <xsl:template match="css:rules | css:rules/@* | dbk:tabs | dbk:tab | dbk:tab/@*" mode="default">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- DEFAULT ATTRIBUTE HANDLING -->

  <xsl:template match="@xml:id" mode="default">
    <xsl:attribute name="id" select="."/>
  </xsl:template>

  <xsl:template match="@role" mode="default">
    <xsl:param name="elt-name" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="$elt-name">
        <xsl:attribute name="book-part-type" select="."/>    
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="content-type" select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:key name="by-id" match="*[@id | @xml:id]" use="@id | @xml:id"/>
  
  <xsl:template match="@linkend | @linkends" mode="default">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="@linkend | @linkends" mode="clean-up">
    <xsl:param name="root" select="root()" as="document-node(element(*))" tunnel="yes"/>
    <xsl:variable name="targets" select="key('by-id', tokenize(., '\s+'), $root)" as="element(*)*"/>
    <xsl:variable name="types" select="jats:ref-types($targets)" as="xs:string*"/>
    <xsl:if test="count($types) eq 1">
      <xsl:attribute name="ref-type" select="$types[1]"/>
    </xsl:if>
    <xsl:attribute name="rid" select="."/>
  </xsl:template>

  <xsl:function name="jats:ref-types" as="xs:string*">
    <xsl:param name="targets" as="element(*)*"/>
    <xsl:variable name="names" select="distinct-values($targets/local-name())" as="xs:string*"/>
    <xsl:sequence select="for $n in $names return jats:ref-type($n)"/>
  </xsl:function>
  
  <xsl:function name="jats:ref-type" as="xs:string?">
    <xsl:param name="elt-name" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$elt-name eq 'app'">
        <xsl:sequence select="'app'"/>
      </xsl:when>
      <xsl:when test="$elt-name = ('ref', 'mixed-citation')">
        <xsl:sequence select="'bibr'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'boxed-text'">
        <xsl:sequence select="'boxed-text'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'disp-formula'">
        <xsl:sequence select="'disp-formula'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'fig'">
        <xsl:sequence select="'fig'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'fn'">
        <xsl:sequence select="'fn'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'sec'">
        <xsl:sequence select="'sec'"/>
      </xsl:when>
      <xsl:when test="$elt-name eq 'table-wrap'">
        <xsl:sequence select="'table'"/>
      </xsl:when>
      <xsl:when test="$elt-name = ('book-part')">
        <xsl:sequence select="'book-part'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>hub2hobots: unknown ref-type for <xsl:value-of select="$elt-name"/></xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="@remap | @annotations" mode="default"/>

  <xsl:template match="@css:* | css:rule/@*" mode="default">
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
      <xsl:when test="$name = ('info', 'title', 'subtitle')"><xsl:sequence select="''"/></xsl:when>
      <xsl:when test="$name = ('toc', 'preface', 'partintro', 'acknowledgements', 'dedication')"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:colophon[@role eq 'front-matter-blurb']"><xsl:sequence select="'front-matter'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:part[jats:is-appendix-part(.)]"><xsl:sequence select="'book-back'"/></xsl:when>
      <xsl:when test="$name = ('part', 'chapter')"><xsl:sequence select="'book-body'"/></xsl:when>
      <xsl:when test="$name = ('appendix', 'index', 'glossary', 'bibliography')"><xsl:sequence select="'book-back'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'dark-matter'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="dbk:book | dbk:hub" mode="default" priority="2">
    <book>
      <xsl:namespace name="css" select="'http://www.w3.org/1996/css'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:copy-of select="@css:version"/>
      <xsl:attribute name="css:rule-selection-attribute" select="'content-type style-type'"/>
      <xsl:attribute name="source-dir-uri" select="dbk:info/dbk:keywordset[@role eq 'hub']/dbk:keyword[@role eq 'source-dir-uri']"/>      
      <xsl:sequence select="$dtd-version-att"/>
      <xsl:choose>
        <xsl:when test="@xml:lang">
          <xsl:copy-of select="@xml:lang"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="key('jats:style-by-type', 'NormalParagraphStyle')[@xml:lang ne '']">
            <xsl:copy-of select="key('jats:style-by-type', 'NormalParagraphStyle')/@xml:lang, @xml:lang"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <book-meta>
        <book-title-group>
          <xsl:apply-templates select="dbk:info/dbk:title | dbk:title" mode="#current"/>
          <xsl:apply-templates select="dbk:info/dbk:subtitle | dbk:subtitle" mode="#current"/>
        </book-title-group>
        <xsl:if test="dbk:info/dbk:authorgroup or dbk:authorgroup">
        <contrib-group>
          <xsl:apply-templates select="dbk:info/dbk:authorgroup | dbk:authorgroup" mode="#current"/>
        </contrib-group>
        </xsl:if>
        <custom-meta-group>
          <xsl:apply-templates select="dbk:info/css:rules" mode="#current"/>  
        </custom-meta-group>
        <!--<xsl:apply-templates select="dbk:info[dbk:keywordset[@role eq 'hub']]" mode="#current"/>-->
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
  
  <xsl:template match="dbk:keywordset" mode="default">
    <custom-meta-group>
      <xsl:apply-templates mode="#current"/>
    </custom-meta-group>
  </xsl:template>
  
  <xsl:template match="dbk:keyword" mode="default">
    <custom-meta>
      <meta-name>
        <xsl:value-of select="@role"/>
      </meta-name>
      <meta-value>
        <xsl:value-of select="."/>
      </meta-value>
    </custom-meta>
  </xsl:template>
  
  <xsl:template match="dbk:authorgroup | dbk:org | dbk:orgname" mode="default" priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="dbk:affiliation" mode="default" priority="2">
    <aff>
      <xsl:apply-templates mode="#current"/>
    </aff>
  </xsl:template>
  
  <xsl:template match="dbk:personblurb" mode="default" priority="2">
    <bio>
      <xsl:apply-templates mode="#current"/>
    </bio>
  </xsl:template>
 
  <xsl:template match="dbk:toc" mode="default">
    <toc>
      <xsl:apply-templates select="." mode="toc-depth"/>
      <xsl:call-template name="css:content"/>
    </toc>
  </xsl:template>

  <xsl:template match="dbk:toc/dbk:title | dbk:index/dbk:title" mode="default" priority="2">
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
  
  <xsl:template match="@renderas" mode="default">
    <xsl:attribute name="disp-level" select="."/>
  </xsl:template>

  <xsl:template match="dbk:appendix" mode="default">
    <app>
      <xsl:apply-templates select="@*, * except dbk:info, dbk:info" mode="#current"/>
    </app>
  </xsl:template>

  <xsl:template match="dbk:acknowledgements | dbk:preface[@role = 'acknowledgements']" mode="default">
    <ack><xsl:call-template name="css:content"/></ack>
  </xsl:template>
  
  <xsl:template match="dbk:preface[@role = 'acknowledgements']/@role" mode="default" priority="2"/>

  <xsl:template match="dbk:glossary" mode="default">
    <xsl:choose>
      <xsl:when test="ancestor::*/self::dbk:part[jats:is-appendix-part(.)]">
        <app>
          <glossary>
            <xsl:apply-templates select="@*, * except dbk:info, dbk:info" mode="#current"/>
          </glossary>
        </app>
      </xsl:when>
      <xsl:otherwise>
        <glossary>
          <xsl:apply-templates select="@*, * except dbk:info, dbk:info" mode="#current"/>
        </glossary>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  
  <xsl:template match="dbk:index" mode="default">
    <index>
      <xsl:apply-templates select="@*, dbk:title" mode="#current"/>
      <!-- will be filled in clean-up -->
    </index>
  </xsl:template>
  

  <xsl:function name="jats:book-part" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:part[jats:is-appendix-part(.)]"><xsl:sequence select="'app-group'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:part or $elt/self::dbk:chapter"><xsl:sequence select="'book-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:partintro
                      | $elt/self::dbk:colophon[@role eq 'front-matter-blurb']"><xsl:sequence select="'front-matter-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'foreword')]"><xsl:sequence select="'foreword'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'acknowledgements')]"><xsl:sequence select="'ack'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface[matches(@role, 'praise')]"><xsl:sequence select="'front-matter-part'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:preface"><xsl:sequence select="'preface'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:dedication"><xsl:sequence select="'dedication'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:acknowledgements"><xsl:sequence select="'ack'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:glossary"><xsl:sequence select="'glossary'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:index"><xsl:sequence select="'index'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="'unknown-book-part'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="jats:is-appendix-part" as="xs:boolean">
    <xsl:param name="elt" as="element(dbk:part)"/>
    <xsl:sequence select="every $c in $elt/* satisfies $c/name() = ('appendix', 'index', 'bibliography', 'glossary', 'title', 'subtitle', 'info')"/>
  </xsl:function>

  <xsl:function name="jats:book-part-body" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:part or $elt/self::dbk:chapter"><xsl:sequence select="'body'"/></xsl:when>
      <xsl:when test="local-name($elt) = ('preface', 'partintro', 'dedication', 'preface', 'colophon')"><xsl:sequence select="'named-book-part-body'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="concat('unknown-book-part-body_', $elt/name())"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="jats:part-submatter" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="name($elt) = ('title', 'info')">
        <xsl:sequence select="'book-part-meta'"/>
      </xsl:when>
      <xsl:when test="name($elt) = ('bibliography', 'glossary', 'appendix')">
        <xsl:sequence select="'back'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="jats:book-part-body($elt/..)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template match="dbk:part[jats:is-appendix-part(.)]" mode="default">
    <app-group>
      <xsl:call-template name="css:content"/>
    </app-group>
  </xsl:template>
  
  <xsl:template match="app-group" mode="clean-up">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node() except (ref-list | index)" mode="#current"/>
    </xsl:copy>
    <xsl:apply-templates select="ref-list | index" mode="#current"/>
  </xsl:template>
  
  
  <xsl:template match="  dbk:part | dbk:chapter | dbk:preface[not(@role = 'acknowledgements')] 
                       | dbk:partintro | dbk:colophon | dbk:dedication" mode="default">
    <xsl:variable name="elt-name" as="xs:string" select="jats:book-part(.)"/>
    <xsl:element name="{$elt-name}">
      <xsl:apply-templates select="@*" mode="#current">
        <xsl:with-param name="elt-name" select="$elt-name"/>
      </xsl:apply-templates>
      <xsl:if test="$elt-name eq 'book-part'">
        <xsl:attribute name="book-part-type" select="local-name()"/>
      </xsl:if>
      <xsl:variable name="context" select="." as="element(*)"/>
      <xsl:for-each-group select="*" group-adjacent="jats:part-submatter(.)">
        <xsl:element name="{current-grouping-key()}">
          <xsl:choose>
            <xsl:when test="matches(current-grouping-key(), 'meta')">
              <xsl:call-template name="title-info">
                <xsl:with-param name="elts" select="current-group()/(self::dbk:title union self::dbk:info/*)"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:element>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@renderas[not(parent::dbk:section)]" mode="default"/>
    
  <xsl:template match="dbk:preface/@role" mode="default">
    <xsl:attribute name="book-part-type" select="."/>
  </xsl:template>
  
  <!-- METADATA -->

  <xsl:function name="jats:meta-component" as="xs:string">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::dbk:title or $elt/self::dbk:subtitle"><xsl:sequence select="'title-group'"/></xsl:when>
      <xsl:when test="$elt/self::dbk:authorgroup"><xsl:sequence select="'contrib-group'"/></xsl:when>
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

  <xsl:template match="dbk:book/dbk:title" mode="default">
    <book-title>
      <xsl:apply-templates select="@srcpath, node()" mode="#current"/>
    </book-title>
  </xsl:template> 
  
  <xsl:template match="dbk:subtitle" mode="default">
    <subtitle>
      <xsl:call-template name="css:content"/>
    </subtitle>
  </xsl:template>  
  
  <xsl:template match="dbk:subtitle/dbk:date" mode="default">
    <named-content content-type="edition">
      <xsl:call-template name="css:content"/>
    </named-content>
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
    <title>
      <xsl:call-template name="css:content"/>
    </title>
  </xsl:template>



  <!-- Don’t wrap title content in a bold element -->
  <xsl:template match="@css:font-weight[matches(., '^bold|[6-9]00$')]" mode="css:map-att-to-elt" as="xs:string?">
    <xsl:param name="context" as="element(*)?"/>
    <xsl:if test="not(
                    $context/local-name() = ('title')
                    or
                    ($context/local-name() = ('phrase') and $context/../local-name() = ('title')) 
                  )">
      <xsl:sequence select="$css:bold-elt-name"/>  
    </xsl:if>
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

  <xsl:template match="dbk:para | dbk:simpara" mode="default">
    <p><xsl:call-template name="css:content"/></p>
  </xsl:template>
  
  <xsl:template match="dbk:blockquote" mode="default">
    <disp-quote><xsl:call-template name="css:content"/></disp-quote>
  </xsl:template>
  
  <!-- INLINE -->
  
  <xsl:variable name="css:italic-elt-name" as="xs:string" select="'italic'"/>
  <xsl:variable name="css:bold-elt-name" as="xs:string" select="'bold'"/>
  <xsl:variable name="css:underline-elt-name" as="xs:string?" select="'underline'"/>
  
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

  <xsl:template match="dbk:link[@xlink:href]/@role" mode="default "/>

  <xsl:template match="dbk:anchor" mode="default">
    <target><xsl:call-template name="css:content"/></target>
  </xsl:template>

  <xsl:template match="dbk:br" mode="default">
    <break/>
  </xsl:template>
  
  <xsl:template match="dbk:superscript" mode="default">
    <sup>
      <xsl:call-template name="css:content"/>
    </sup>
  </xsl:template>
  
  <xsl:template match="dbk:subscript" mode="default">
    <sub>
      <xsl:call-template name="css:content"/>
    </sub>
  </xsl:template>
  
  <!-- INDEXTERMS -->
  
  <xsl:template match="dbk:indexterm" mode="default">
    <index-term>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="dbk:primary" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:primary" mode="default">
    <term>
      <xsl:call-template name="css:content"/>
    </term>
    <xsl:apply-templates select="if(../dbk:secondary) then ../dbk:secondary else ( dbk:see | dbk:seealso)" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:secondary" mode="default">
    <index-term>
      <term>
        <xsl:call-template name="css:content"/>
      </term>
      <xsl:apply-templates select="if(../dbk:tertiary) then ../dbk:tertiary else ( dbk:see | dbk:seealso)" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:tertiary" mode="default">
    <index-term>
      <term>
        <xsl:call-template name="css:content"/>
      </term>
      <xsl:apply-templates select="dbk:see | dbk:seealso" mode="#current"/>
    </index-term>
  </xsl:template>
  
  <xsl:template match="dbk:see" mode="default">
    <see>
      <xsl:call-template name="css:content"/>
    </see>
  </xsl:template>
  
  <xsl:template match="dbk:seealso" mode="default">
    <see-also>
      <xsl:call-template name="css:content"/>
    </see-also>
  </xsl:template>
  
  <!-- FOOTNOTES -->
  
  <xsl:template match="dbk:footnote" mode="default">
    <fn><xsl:call-template name="css:content"/></fn>
  </xsl:template>
  
  <!-- LISTS -->
  
  <xsl:template match="dbk:variablelist" mode="default">
    <def-list>
      <xsl:attribute name="id" select="generate-id()"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def-list>
  </xsl:template>
  
  <xsl:template match="dbk:varlistentry" mode="default">
    <def-item>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def-item>
  </xsl:template>

  <xsl:template match="dbk:varlistentry/dbk:term" mode="default">
    <term>
      <xsl:call-template name="css:content"/>
    </term>
  </xsl:template>
  
  <xsl:template match="dbk:varlistentry/dbk:listitem" mode="default">
    <def>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </def>
  </xsl:template>
  
  <xsl:template match="dbk:orderedlist" mode="default">
    <list list-type="order">
      <xsl:attribute name="id" select="generate-id()"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </list>
  </xsl:template>
  
  <xsl:template match="dbk:itemizedlist" mode="default">
    <list list-type="bullet">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </list>
  </xsl:template>
  
  <xsl:template match="@numeration" mode="default">
    <xsl:choose>
      <xsl:when test=". = 'arabic'"><xsl:attribute name="list-type" select="'order'"/></xsl:when>
      <xsl:when test=". = 'upperalpha'"><xsl:attribute name="list-type" select="'alpha-upper'"/></xsl:when> 
      <xsl:when test=". = 'loweralpha'"><xsl:attribute name="list-type" select="'alpha-lower'"/></xsl:when>
      <xsl:when test=". = 'upperroman'"><xsl:attribute name="list-type" select="'roman-upper'"/></xsl:when> 
      <xsl:when test=". = 'lowerroman'"><xsl:attribute name="list-type" select="'roman-lower'"/></xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@continuation[. = 'continues']" mode="default">
    <xsl:variable name="preceding-list" select="../preceding-sibling::dbk:orderedlist[1]" as="element(dbk:orderedlist)?"/>
    <xsl:attribute name="continued-from" select="$preceding-list/(@xml:id, generate-id())[1]"/>    
    <xsl:if test="not($preceding-list)">
      <xsl:message>hub2hobots: No list to continue found. Look for an empty continued-from attribute in the output.</xsl:message>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="@startingnumber" mode="default">
    <xsl:message>hub2hobots: No startingnumber support in BITS. Attribute copied nonetheless.</xsl:message>
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="dbk:listitem" mode="default">
    <list-item>
      <xsl:apply-templates select="@* except @override, @override, node()" mode="#current"/>
    </list-item>
  </xsl:template>
  
  <xsl:template match="dbk:listitem/@override" mode="default">
    <label>
      <xsl:value-of select="."/>
    </label>
  </xsl:template>
  
  <xsl:template match="dbk:itemizedlist/@mark" mode="default">
    <xsl:variable name="type" as="xs:string?">
      <xsl:choose>
        <xsl:when test=". = '&#x25fd;'"><xsl:value-of select="'box'"/></xsl:when>
        <xsl:when test=". = '&#x2713;'"><xsl:value-of select="'check'"/></xsl:when>
        <xsl:when test=". = '&#x25e6;'"><xsl:value-of select="'circle'"/></xsl:when>
        <xsl:when test=". = '&#x25c6;'"><xsl:value-of select="'diamond'"/></xsl:when>
        <xsl:when test=". = '&#x2022;'"><xsl:value-of select="'disc'"/></xsl:when>
        <xsl:when test=". = ('&#x2013;', '&#x2014;')"><xsl:value-of select="'dash'"/></xsl:when>
        <xsl:when test=". = '&#x25fe;'"><xsl:value-of select="'square'"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$type">
      <xsl:attribute name="css:list-style-type" select="$type"/>  
    </xsl:if>
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
  
  <xsl:template match="dbk:sidebar[@remap eq 'Group']" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <!-- POETRY -->
  
  <xsl:template match="dbk:poetry | dbk:poetry/dbk:linegroup" mode="default">
    <verse-group>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </verse-group>
  </xsl:template>
  
  <xsl:template match="dbk:poetry/dbk:linegroup/dbk:line" mode="default">
    <verse-line>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </verse-line>
  </xsl:template>
  <!-- FIGURES -->
  
  <xsl:template match="dbk:figure" mode="default">
    <fig>
      <xsl:call-template name="css:other-atts"/>
      <xsl:apply-templates select="(.//dbk:anchor)[1]/@xml:id" mode="#current"/>
      <label>
        <xsl:apply-templates mode="#current" select="dbk:title/dbk:phrase[@role eq 'hub:caption-number']"/>
      </label>
      <caption>
        <title>
          <xsl:apply-templates mode="#current"
            select="dbk:title/(node() except (dbk:phrase[@role eq 'hub:caption-number'] | dbk:tab))"/>
        </title>
      </caption>
      <xsl:apply-templates select="* except (dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']])" mode="#current"/>
      <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
    </fig>
  </xsl:template>
  
  <xsl:template match="dbk:figure/dbk:note" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  
  <xsl:template match="dbk:info[count(*) eq 1][dbk:legalnotice[@role eq 'copyright']]" mode="default">
    <permissions>
      <xsl:apply-templates mode="#current"/>
    </permissions>
  </xsl:template>
  
  <xsl:template match="dbk:info[count(*) eq 1]/dbk:legalnotice[@role eq 'copyright']" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:info[count(*) eq 1]/dbk:legalnotice[@role eq 'copyright']/dbk:para" mode="default">
    <copyright-statement>
      <xsl:apply-templates select="@* except @role, node()" mode="#current"/>
    </copyright-statement>
  </xsl:template>
  
  <xsl:template match="dbk:mediaobject | dbk:inlinemediaobject | dbk:imageobject" mode="default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dbk:imagedata" mode="default">
    <xsl:element name="{if (
                              not(name(../../..) = ('figure', 'entry'))
                              or
                              name(../..) = 'inlinemediaobject'
                              ) 
                        then 'inline-graphic' 
                        else 'graphic'}">
      <xsl:apply-templates select="(ancestor::dbk:mediaobject | ancestor::dbk:inlinemediaobject)[1]/@xml:id" mode="#current"/>
      <xsl:call-template name="css:content"/>
    </xsl:element>
  </xsl:template>
  
  <!-- Override in adaptions -->
  <xsl:template match="dbk:imagedata/@fileref" mode="default">
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>
  
  <!-- TABLES -->
  
  <!-- todo: group with table footnotes -->
    
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

  <xsl:template match="dbk:colspec[@colwidth]" mode="default">
    <col>
      <xsl:apply-templates select="@colwidth" mode="#current"/>
    </col>
  </xsl:template>
  
  <xsl:template match="dbk:colspec/@colwidth" mode="default">
    <xsl:attribute name="width" select="."/>
  </xsl:template>
  
  <xsl:template match="dbk:table/@css:width | dbk:informaltable/@css:width" mode="default">
    <xsl:attribute name="{local-name()}" select="."/>
    <xsl:copy/>
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
    <xsl:if test="xs:integer(.) ge 1">
      <xsl:attribute name="rowspan" select=". + 1"/>
    </xsl:if>
  </xsl:template>
  
   <xsl:template match="dbk:table/dbk:title" name="dbk:table-title" mode="default" priority="2">
     <label>
       <xsl:apply-templates mode="#current" select="dbk:phrase[@role eq 'hub:caption-number']"/>
     </label>
     <caption>
       <title>
         <xsl:apply-templates mode="#current"
           select="node() except (dbk:phrase[@role eq 'hub:caption-number'] | dbk:tab)"/>
       </title>
       <xsl:if test="../dbk:caption">
         <xsl:apply-templates select="../dbk:caption/dbk:para" mode="#current"/>
       </xsl:if>
     </caption>
   </xsl:template>
  
  <xsl:template match="dbk:caption" mode="clean-up"/>
  
  
  <xsl:template match="dbk:informaltable | dbk:table" mode="default">
    <table-wrap>
      <xsl:apply-templates select="@* except (@role | @css:*), dbk:title" mode="#current"/>
      <table>
        <!--<xsl:for-each select="self::dbk:informaltable">
          <xsl:call-template name="css:other-atts"/>
        </xsl:for-each>-->
        <!-- extra content-type attribute at the contained table (also process css here, only id above?): -->
        <xsl:apply-templates select="@role | @css:*" mode="#current"/>
        <xsl:choose>
          <xsl:when test="exists(dbk:tgroup/*/dbk:row)">
            <xsl:apply-templates select="* except (dbk:title | dbk:info[dbk:legalnotice[@role eq 'copyright']])" mode="#current"/>
            <xsl:apply-templates select="dbk:info[dbk:legalnotice[@role eq 'copyright']]" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <HTMLTABLE_TODO/>
            <xsl:apply-templates mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </table>  
    </table-wrap>
  </xsl:template>
  
  <xsl:template match="dbk:informaltable" mode="default_DISABLED">
    <array>
      <xsl:call-template name="css:content"/>
    </array>  
  </xsl:template>
  
  <xsl:template match="dbk:colspec | @colname | @nameend" mode="default"/>
  
  
  <!-- EPUB conditional content -->
  
  <xsl:template match="@condition" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>
  
  <!-- BIBLIOGRAPHY -->
  
  <xsl:template match="dbk:bibliography | dbk:bibliodiv" mode="default">
    <ref-list>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </ref-list>
  </xsl:template>

  <xsl:template match="dbk:biblioentry/@annotations" mode="default">
    <xsl:attribute name="specific-use" select="."/>
  </xsl:template>

  <xsl:template match="dbk:biblioentry" mode="default">
    <ref><xsl:call-template name="css:content"/></ref>
  </xsl:template>
  
  <xsl:template match="dbk:bibliomisc" mode="default">
    <mixed-citation>
      <xsl:if test="../@xml:id">
        <xsl:attribute name="id" select="../@xml:id"/>  
      </xsl:if>
      <xsl:call-template name="css:content"/>
    </mixed-citation>
  </xsl:template>
  
  <xsl:template match="dbk:biblioentry/@xml:id" mode="default"/>
  
  <xsl:template match="mixed-citation/@*[name() = ('css:margin-left', 'css:text-indent', 'content-type')]" mode="clean-up"/>
  
</xsl:stylesheet>