require File.dirname(__FILE__) + '/../spec_helper'

context "Given a valid audioscrobbler RDF with 3 items in it" do
  setup do
    @audioscrobbler = Audioscrobbler.new('', false)
    @audioscrobbler.send(:parse, fixture)
  end

  specify "parser finds 3 items" do
    @audioscrobbler.should_have(3).items
  end

  specify "title should be: Audioscrobbler Musical Profile: benjackson" do
    @audioscrobbler.title.should == 'Audioscrobbler Musical Profile: benjackson'
  end

  specify "link should be: http://www.audioscrobbler.com/user/benjackson/" do
    @audioscrobbler.link.should == "http://www.audioscrobbler.com/user/benjackson/"
  end

  specify "first item is parsed correctly" do
    item = @audioscrobbler.items.first

    item.artist.should == "Badly Drawn Boy"
    item.title.should  == "Life Turned Upside Down"
    item.link.should   == "http://www.audioscrobbler.com/music/Badly+Drawn+Boy/_/Life+Turned+Upside+Down"
  end


  def fixture
    <<EORDF
<rdf:RDF>
    <channel rdf:about="http://ws.audioscrobbler.com/rdf/history/benjackson">
    <title>Audioscrobbler Musical Profile: benjackson</title>
    <link>http://www.audioscrobbler.com/user/benjackson/</link>

        <description>
    benjackson's last played tracks, as recorded by Audioscrobbler.com
    </description>
    <cc:license rdf:resource="http://www.creativecommons.org/licenses/by-nc-sa/1.0/"/>
    <dc:creator>benjackson</dc:creator>
    <dc:date>2005-08-03T2:33:30+00:00</dc:date>
    <admin:generatorAgent rdf:resource="http://www.audioscrobbler.com/"/>
    <admin:errorReportsTo rdf:resource="mailto:support@audioscrobbler.com"/>

        <items>

        <rdf:Seq>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    <rdf:li rdf:resource="http://mm.musicbrainz.org/track/MBIDHERE"/>
    </rdf:Seq>
    </items>
    </channel>

        <item rdf:about="http://mm.musicbrainz.org/track/MBIDHERE">

        <link>http://www.audioscrobbler.com/music/Badly+Drawn+Boy/_/Life+Turned+Upside+Down</link>
    <description>Badly Drawn Boy - Life Turned Upside Down</description>
    <guid isPermaLink="false">8394@www.audioscrobbler.com/user/benjackson/</guid>
    <dc:date>2005-08-03T02:31:18+00:00</dc:date>
    <dc:title>Life Turned Upside Down</dc:title>

        <mm:Artist rdf:about="http://mm.musicbrainz.org/artist/0881daf1-20df-4a3e-a84f-6476a84bb172">

        <dc:creator>
    <dc:title>Badly Drawn Boy</dc:title>
    </dc:creator>
    </mm:Artist>

        <mm:albumlist>

        <mm:Album rdf:about="http://mm.musicbrainz.org/album/MBIDHERE">
    <dc:title>One Plus One Is One</dc:title>
    </mm:Album>
    </mm:albumlist>
    </item>

        <item rdf:about="http://mm.musicbrainz.org/track/MBIDHERE">

        <link>http://www.audioscrobbler.com/music/Badly+Drawn+Boy/_/Logic+of+a+Friend</link>
    <description>Badly Drawn Boy - Logic of a Friend</description>
    <guid isPermaLink="false">8393@www.audioscrobbler.com/user/benjackson/</guid>
    <dc:date>2005-08-03T02:26:39+00:00</dc:date>
    <dc:title>Logic of a Friend</dc:title>

        <mm:Artist rdf:about="http://mm.musicbrainz.org/artist/0881daf1-20df-4a3e-a84f-6476a84bb172">

        <dc:creator>
    <dc:title>Badly Drawn Boy</dc:title>
    </dc:creator>
    </mm:Artist>

        <mm:albumlist>

        <mm:Album rdf:about="http://mm.musicbrainz.org/album/MBIDHERE">
    <dc:title>One Plus One Is One</dc:title>
    </mm:Album>
    </mm:albumlist>
    </item>

        <item rdf:about="http://mm.musicbrainz.org/track/MBIDHERE">

        <link>http://www.audioscrobbler.com/music/Badly+Drawn+Boy/_/Four+Leaf+Clover</link>
    <description>Badly Drawn Boy - Four Leaf Clover</description>
    <guid isPermaLink="false">8392@www.audioscrobbler.com/user/benjackson/</guid>
    <dc:date>2005-08-03T02:22:17+00:00</dc:date>
    <dc:title>Four Leaf Clover</dc:title>

        <mm:Artist rdf:about="http://mm.musicbrainz.org/artist/0881daf1-20df-4a3e-a84f-6476a84bb172">

        <dc:creator>
    <dc:title>Badly Drawn Boy</dc:title>
    </dc:creator>
    </mm:Artist>

        <mm:albumlist>

        <mm:Album rdf:about="http://mm.musicbrainz.org/album/MBIDHERE">
    <dc:title>One Plus One Is One</dc:title>
    </mm:Album>
    </mm:albumlist>
    </item>
</rdf:RDF>
EORDF
  end
end
