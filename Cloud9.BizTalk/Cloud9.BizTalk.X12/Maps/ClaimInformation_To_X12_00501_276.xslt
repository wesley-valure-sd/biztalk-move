<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ns0="temp">

  <xsl:template name="CreateHLSegments">

    <!--Payer Information-->
    <xsl:call-template name="OutputHLSegment">
      <xsl:with-param name="HL01" select="'1'"/>
      <xsl:with-param name="HL02" select="''"/>
      <xsl:with-param name="HL03" select="'20'"/>
      <xsl:with-param name="HL04" select="'1'"/>
    </xsl:call-template>

    <!--Submitter Information-->
    <xsl:call-template name="OutputHLSegment">
      <xsl:with-param name="HL01" select="'2'"/>
      <xsl:with-param name="HL02" select="'1'"/>
      <xsl:with-param name="HL03" select="'21'"/>
      <xsl:with-param name="HL04" select="'1'"/>
    </xsl:call-template>

    <!--Provider Information-->
    <xsl:call-template name="OutputHLSegment">
      <xsl:with-param name="HL01" select="'3'"/>
      <xsl:with-param name="HL02" select="'2'"/>
      <xsl:with-param name="HL03" select="'19'"/>
      <xsl:with-param name="HL04" select="'1'"/>
    </xsl:call-template>

    <!--Patient Information-->
    <xsl:call-template name="OutputHLSegment">
      <xsl:with-param name="HL01" select="'4'"/>
      <xsl:with-param name="HL02" select="'3'"/>
      <xsl:with-param name="HL03" select="'22'"/>
      <xsl:with-param name="HL04" select="'0'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="OutputHLSegment">
    <xsl:param name="HL01"/>
    <xsl:param name="HL02"/>
    <xsl:param name="HL03"/>
    <xsl:param name="HL04"/>

    <xsl:element name="ns0:HLLoop1">

      <xsl:element name="ns0:HL">
        <xsl:element name="HL01">
          <xsl:value-of select="$HL01"/>
        </xsl:element>
        <xsl:element name="HL02">
          <xsl:value-of select="$HL02"/>
        </xsl:element>
        <xsl:element name="HL03">
          <xsl:value-of select="$HL03"/>
        </xsl:element>
        <xsl:element name="HL04">
          <xsl:value-of select="$HL04"/>
        </xsl:element>
      </xsl:element>

      <!--Payer Information-->
      <xsl:if test="$HL03 = '20'">
        <xsl:call-template name="OutputNM1Segment">
          <xsl:with-param name="NM101" select="'PR'"/>
          <xsl:with-param name="NM102" select="'2'"/>
          <xsl:with-param name="NM103" select="//*[local-name()='PayerName']"/>
          <xsl:with-param name="NM104" select="''"/>
          <xsl:with-param name="NM105" select="''"/>
          <xsl:with-param name="NM106" select="''"/>
          <xsl:with-param name="NM107" select="''"/>
          <xsl:with-param name="NM108" select="'PI'"/>
          <xsl:with-param name="NM109" select="//*[local-name()='GroupNumber']"/>
        </xsl:call-template>
      </xsl:if>

      <!--Submitter Information-->
      <xsl:if test="$HL03 = '21'">
        <xsl:call-template name="OutputNM1Segment">
          <xsl:with-param name="NM101" select="'41'"/>
          <xsl:with-param name="NM102" select="'1'"/>
          <xsl:with-param name="NM103" select="//*[local-name()='SubscriberLastName']"/>
          <xsl:with-param name="NM104" select="//*[local-name()='SubscriberFirstName']"/>
          <xsl:with-param name="NM105" select="''"/>
          <xsl:with-param name="NM106" select="''"/>
          <xsl:with-param name="NM107" select="''"/>
          <xsl:with-param name="NM108" select="'46'"/>
          <xsl:with-param name="NM109" select="//*[local-name()='PolicyNumber']"/>
        </xsl:call-template>
      </xsl:if>

      <!--Provider Information-->
      <xsl:if test="$HL03 = '19'">
        <xsl:call-template name="OutputNM1Segment">
          <xsl:with-param name="NM101" select="'1P'"/>
          <xsl:with-param name="NM102" select="'1'"/>
          <xsl:with-param name="NM103" select="//*[local-name()='ProviderName']"/>
          <xsl:with-param name="NM104" select="''"/>
          <xsl:with-param name="NM105" select="''"/>
          <xsl:with-param name="NM106" select="''"/>
          <xsl:with-param name="NM107" select="''"/>
          <xsl:with-param name="NM108" select="'FI'"/>
          <xsl:with-param name="NM109" select="//*[local-name()='ProviderTaxID']"/>
        </xsl:call-template>
      </xsl:if>

      <!--Patient Information-->
      <xsl:if test="$HL03 = '22'">

        <xsl:element name="ns0:DMG">
          <xsl:element name="DMG01">
            <xsl:value-of select="'D8'"/>
          </xsl:element>
          <xsl:element name="DMG02">
            <xsl:variable name="PatientDOB" select="//*[local-name()='PatientDOB']"/>
            <xsl:value-of select="concat(substring($PatientDOB, 1, 4) ,substring($PatientDOB, 6, 2), substring($PatientDOB, 9, 2))"/>
          </xsl:element>
          <xsl:element name="DMG03">
            <xsl:value-of select="//*[local-name()='PatientGender']"/>
          </xsl:element>
        </xsl:element>

        <xsl:call-template name="OutputNM1Segment">
          <xsl:with-param name="NM101" select="'IL'"/>
          <xsl:with-param name="NM102" select="'1'"/>
          <xsl:with-param name="NM103" select="//*[local-name()='PatientLastName']"/>
          <xsl:with-param name="NM104" select="//*[local-name()='PatientFirstName']"/>
          <xsl:with-param name="NM105" select="''"/>
          <xsl:with-param name="NM106" select="''"/>
          <xsl:with-param name="NM107" select="''"/>
          <xsl:with-param name="NM108" select="'MI'"/>
          <xsl:with-param name="NM109" select="//*[local-name()='PatientIdentifier']"/>
        </xsl:call-template>

        <xsl:element name="ns0:TRNLoop1">
          <xsl:element name="ns0:TRN">
            <xsl:element name="TRN01">
              <xsl:value-of select="'1'"/>
            </xsl:element>
            <xsl:element name="TRN02">
              <xsl:value-of select="//*[local-name()='ClaimNumber']"/>
            </xsl:element>
          </xsl:element>
          <xsl:element name="ns0:AMT">
            <xsl:element name="AMT01">
              <xsl:value-of select="'T3'"/>
            </xsl:element>
            <xsl:element name="AMT02">
              <xsl:value-of select="format-number(//*[local-name()='ClaimAmount'], '#.00')"/>
            </xsl:element>
          </xsl:element>
          <xsl:element name="ns0:DTP">
            <xsl:element name="DTP01">
              <xsl:value-of select="'472'"/>
            </xsl:element>
            <xsl:element name="DTP02">
              <xsl:value-of select="'RD8'"/>
            </xsl:element>
            <xsl:element name="DTP03">
              <xsl:variable name="ClaimDateTime" select="//*[local-name()='ClaimDateTime']"/>
              <xsl:variable name="FormattedClaimDate" select="concat(substring(ClaimDateTime, 1, 4) ,substring(ClaimDateTime, 6, 2), substring(ClaimDateTime, 9, 2))"/>
              <xsl:value-of select="concat($FormattedClaimDate, '-', $FormattedClaimDate)" />
            </xsl:element>
          </xsl:element>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <xsl:template name="OutputNM1Segment">
    <xsl:param name="NM101"/>
    <xsl:param name="NM102"/>
    <xsl:param name="NM103"/>
    <xsl:param name="NM104"/>
    <xsl:param name="NM105"/>
    <xsl:param name="NM106"/>
    <xsl:param name="NM107"/>
    <xsl:param name="NM108"/>
    <xsl:param name="NM109"/>

    <xsl:element name="ns0:NM1Loop2">
      <xsl:element name="ns0:NM1_2">
        <xsl:element name="NM101">
          <xsl:value-of select="$NM101"/>
        </xsl:element>
        <xsl:element name="NM102">
          <xsl:value-of select="$NM102"/>
        </xsl:element>
        <xsl:element name="NM103">
          <xsl:value-of select="$NM103"/>
        </xsl:element>
        <xsl:element name="NM104">
          <xsl:value-of select="$NM104"/>
        </xsl:element>
        <xsl:element name="NM105">
          <xsl:value-of select="$NM105"/>
        </xsl:element>
        <xsl:element name="NM106">
          <xsl:value-of select="$NM106"/>
        </xsl:element>
        <xsl:element name="NM107">
          <xsl:value-of select="$NM107"/>
        </xsl:element>
        <xsl:element name="NM108">
          <xsl:value-of select="$NM108"/>
        </xsl:element>
        <xsl:element name="NM109">
          <!--<xsl:value-of select="$NM109"/>-->
          <xsl:call-template name="prepend-pad">
            <xsl:with-param name="padChar" select="' '"/>
            <xsl:with-param name="padVar" select="$NM109"/>
            <xsl:with-param name="length" select="2"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template name="prepend-pad">
    <!-- recursive template to right justify and prepend the value with whatever padChar is passed in   -->
    <xsl:param name="padChar"/>
    <xsl:param name="padVar"/>
    <xsl:param name="length"/>
    <xsl:choose>
      <xsl:when test="string-length($padVar) &lt; $length">
        <xsl:call-template name="prepend-pad">
          <xsl:with-param name="padChar" select="$padChar"/>
          <xsl:with-param name="padVar" select="concat($padChar,$padVar)"/>
          <xsl:with-param name="length" select="$length"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring($padVar,string-length($padVar) - $length + 1)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>