require 'spec_helper'

describe 'ChunyPNG.Color' do
  it 'should interpret 4 arguments as RGBA values' do
    ChunkyPNG::Color(1, 2, 3, 4).should == ChunkyPNG::Color.rgba(1, 2, 3, 4)
  end

  it 'should interpret 3 arguments as RGBA values' do
    ChunkyPNG::Color(1, 2, 3).should == ChunkyPNG::Color.rgb(1, 2, 3)
  end

  it 'should interpret 2 arguments as a color to parse and an opacity value' do
    ChunkyPNG::Color('0x0a649664', 0xaa).should == 0x0a6496aa
    ChunkyPNG::Color('spring green @ 0.6666', 0xff).should == 0x00ff7fff
  end

  it 'should interpret 1 argument as a color to parse' do
    expect(ChunkyPNG::Color).to receive(:parse).with('0x0a649664')
    ChunkyPNG::Color('0x0a649664')
  end
end

describe ChunkyPNG::Color do
  include ChunkyPNG::Color

  before(:each) do
    @white             = 0xffffffff
    @black             = 0x000000ff
    @opaque            = 0x0a6496ff
    @non_opaque        = 0x0a649664
    @fully_transparent = 0x0a649600
    @red               = 0xff0000ff
    @green             = 0x00ff00ff
    @blue              = 0x0000ffff
  end

  describe '#parse' do
    it 'should interpret a hex string correctly' do
      parse('0x0a649664').should == ChunkyPNG::Color.from_hex('#0a649664')
    end

    it 'should interpret a color name correctly' do
      parse(:spring_green).should == 0x00ff7fff
      parse('spring green').should == 0x00ff7fff
      parse('spring green @ 0.6666').should == 0x00ff7faa
    end

    it 'should return numbers as is' do
      parse('12345').should == 12345
      parse(12345).should == 12345
    end
  end

  describe '#pixel_bytesize' do
    it 'should return the normal amount of bytes with a bit depth of 8' do
      pixel_bytesize(ChunkyPNG::COLOR_TRUECOLOR, 8).should == 3
    end

    it 'should return a multiple of the normal amount of bytes with a bit depth greater than 8' do
      pixel_bytesize(ChunkyPNG::COLOR_TRUECOLOR, 16).should == 6
      pixel_bytesize(ChunkyPNG::COLOR_TRUECOLOR_ALPHA, 16).should == 8
      pixel_bytesize(ChunkyPNG::COLOR_GRAYSCALE_ALPHA, 16).should == 4
    end

    it 'should return 1 with a bit depth lower than 0' do
      pixel_bytesize(ChunkyPNG::COLOR_TRUECOLOR, 4).should == 1
      pixel_bytesize(ChunkyPNG::COLOR_INDEXED, 2).should == 1
      pixel_bytesize(ChunkyPNG::COLOR_GRAYSCALE_ALPHA, 1).should == 1
    end
  end

  describe '#pass_bytesize' do
    it 'should calculate a pass size correctly' do
      pass_bytesize(ChunkyPNG::COLOR_TRUECOLOR, 8, 10, 10).should == 310
    end

    it 'should return 0 if one of the dimensions is zero' do
      pass_bytesize(ChunkyPNG::COLOR_TRUECOLOR, 8, 0, 10).should == 0
      pass_bytesize(ChunkyPNG::COLOR_TRUECOLOR, 8, 10, 0).should == 0
    end
  end

  describe '#rgba' do
    it 'should represent pixels as the correct number' do
      rgba(255, 255, 255, 255).should == @white
      rgba(  0,   0,   0, 255).should == @black
      rgba( 10, 100, 150, 255).should == @opaque
      rgba( 10, 100, 150, 100).should == @non_opaque
      rgba( 10, 100, 150,   0).should == @fully_transparent
    end
  end

  describe '#from_hex' do
    it 'should load colors correctly from hex notation' do
      from_hex('0a649664').should   == @non_opaque
      from_hex('#0a649664').should  == @non_opaque
      from_hex('0x0a649664').should == @non_opaque
      from_hex('0a6496').should     == @opaque
      from_hex('#0a6496').should    == @opaque
      from_hex('0x0a6496').should   == @opaque
      from_hex('abc').should        == 0xaabbccff
      from_hex('#abc').should       == 0xaabbccff
      from_hex('0xabc').should      == 0xaabbccff
    end

    it 'should allow setting opacity explicitly' do
      from_hex('0x0a6496', 0x64).should == @non_opaque
      from_hex('#0a6496', 0x64).should  == @non_opaque
      from_hex('0xabc', 0xdd).should    == 0xaabbccdd
      from_hex('#abc', 0xdd).should     == 0xaabbccdd
    end
  end

  describe '#from_hsv' do
    it 'should load colors correctly from an HSV triple' do
      # At 0 brightness, should be @black independent of hue or sat
      from_hsv(0, 0, 0).should        == @black
      from_hsv(100, 1, 0).should      == @black
      from_hsv(100, 0.5, 0).should    == @black

      # At brightness 1 and sat 0, should be @white regardless of hue
      from_hsv(0, 0, 1).should        == @white
      from_hsv(100, 0, 1).should      == @white

      # Converting the "pure" colors should work
      from_hsv(0, 1, 1).should        == @red
      from_hsv(120, 1, 1).should      == @green
      from_hsv(240, 1, 1).should      == @blue

      # And, finally, one random color
      from_hsv(120, 0.5, 0.80).should == 0x66cc66ff
    end

    it 'should optionally accept a fourth param for alpha' do
      from_hsv(0, 1, 1, 255).should   == @red
      from_hsv(120, 1, 1, 255).should == @green
      from_hsv(240, 1, 1, 255).should == @blue
      from_hsv(0, 1, 1, 0).should     == 0xff000000 # transparent red
      from_hsv(120, 1, 1, 0).should   == 0x00ff0000 # transparent green
      from_hsv(240, 1, 1, 0).should   == 0x0000ff00 # transparent blue
    end
  end

  describe '#from_hsl' do
    it 'should load colors correctly from an HSL triple' do
      # At 0 lightness, should always be black
      from_hsl(0, 0, 0).should         == @black
      from_hsl(100, 0, 0).should       == @black
      from_hsl(54, 0.5, 0).should      == @black

      # At 1 lightness, should always be white
      from_hsl(0, 0, 1).should         == @white
      from_hsl(0, 0.5, 1).should       == @white
      from_hsl(110, 0, 1).should       == @white

      # 'Pure' colors should work
      from_hsl(0, 1, 0.5).should       == @red
      from_hsl(120, 1, 0.5).should     == @green
      from_hsl(240, 1, 0.5).should     == @blue

      # Random colors
      from_hsl(87.27, 0.5, 0.5686)     == 0x96c85aff
      from_hsl(271.83, 0.5399, 0.4176) == 0x6e31a4ff
      from_hsl(63.6, 0.5984, 0.4882)   == 0xbec732ff
    end

    it 'should optionally accept a fourth param for alpha' do
      from_hsl(0, 1, 0.5, 255).should   == @red
      from_hsl(120, 1, 0.5, 255).should == @green
      from_hsl(240, 1, 0.5, 255).should == @blue
      from_hsl(0, 1, 0.5, 0).should     == 0xff000000 # transparent red
      from_hsl(120, 1, 0.5, 0).should   == 0x00ff0000 # transparent green
      from_hsl(240, 1, 0.5, 0).should   == 0x0000ff00 # transparent blue
    end
  end

  describe '#html_color' do
    it 'should find the correct color value' do
      html_color(:springgreen).should   == 0x00ff7fff
      html_color(:spring_green).should  == 0x00ff7fff
      html_color('springgreen').should  == 0x00ff7fff
      html_color('spring green').should == 0x00ff7fff
      html_color('SpringGreen').should  == 0x00ff7fff
      html_color('SPRING_GREEN').should == 0x00ff7fff
    end

    it 'should set the opacity level explicitly' do
      html_color(:springgreen, 0xff).should == 0x00ff7fff
      html_color(:springgreen, 0xaa).should == 0x00ff7faa
      html_color(:springgreen, 0x00).should == 0x00ff7f00
    end

    it 'should set opacity levels from the color name' do
      html_color('Spring green @ 1.0').should   == 0x00ff7fff
      html_color('Spring green @ 0.666').should == 0x00ff7faa
      html_color('Spring green @ 0.0').should   == 0x00ff7f00
    end

    it 'should raise for an unkown color name' do
      expect { html_color(:nonsense) }.to raise_error(ArgumentError)
    end
  end

  describe '#opaque?' do
    it 'should correctly check for opaqueness' do
      opaque?(@white).should == true
      opaque?(@black).should == true
      opaque?(@opaque).should == true
      opaque?(@non_opaque).should == false
      opaque?(@fully_transparent).should == false
    end
  end

  describe 'extraction of separate color channels' do
    it 'should extract components from a color correctly' do
      r(@opaque).should == 10
      g(@opaque).should == 100
      b(@opaque).should == 150
      a(@opaque).should == 255
    end
  end

  describe '#grayscale_teint' do
    it 'should calculate the correct grayscale teint' do
      grayscale_teint(@opaque).should     == 79
      grayscale_teint(@non_opaque).should == 79
    end
  end

  describe '#to_grayscale' do
    it 'should use the grayscale teint for r, g and b' do
      gs = to_grayscale(@non_opaque)
      r(gs).should == grayscale_teint(@non_opaque)
      g(gs).should == grayscale_teint(@non_opaque)
      b(gs).should == grayscale_teint(@non_opaque)
    end

    it 'should preserve the alpha channel' do
      a(to_grayscale(@non_opaque)).should == a(@non_opaque)
      a(to_grayscale(@opaque)).should == ChunkyPNG::Color::MAX
    end
  end

  describe '#to_hex' do
    it 'should represent colors correcly using hex notation' do
      to_hex(@white).should == '#ffffffff'
      to_hex(@black).should == '#000000ff'
      to_hex(@opaque).should == '#0a6496ff'
      to_hex(@non_opaque).should == '#0a649664'
      to_hex(@fully_transparent).should == '#0a649600'
    end

    it 'should represent colors correcly using hex notation without alpha channel' do
      to_hex(@white, false).should == '#ffffff'
      to_hex(@black, false).should == '#000000'
      to_hex(@opaque, false).should == '#0a6496'
      to_hex(@non_opaque, false).should == '#0a6496'
      to_hex(@fully_transparent, false).should == '#0a6496'
    end
  end

  describe '#to_hsv' do
    it 'should return a [hue, saturation, value] array' do
      to_hsv(@white).should     == [0, 0, 1]
      to_hsv(@black).should     == [0, 0, 0]
      to_hsv(@red).should       == [0, 1, 1]
      to_hsv(@blue).should      == [240, 1, 1]
      to_hsv(@green).should     == [120, 1, 1]
      to_hsv(0x805440ff)[0].should be_within(1).of(19)
      to_hsv(0x805440ff)[1].should be_within(0.01).of(0.5)
      to_hsv(0x805440ff)[2].should be_within(0.01).of(0.5)
    end

    it 'should optionally include the alpha channel' do
      to_hsv(@white, true).should                == [0, 0, 1, 255]
      to_hsv(@red, true).should                  == [0, 1, 1, 255]
      to_hsv(@blue, true).should                 == [240, 1, 1, 255]
      to_hsv(@green, true).should                == [120, 1, 1, 255]
      to_hsv(@opaque, true)[3].should            == 255
      to_hsv(@fully_transparent, true)[3].should == 0
    end
  end

  describe '#to_hsl' do
    it 'should return a [hue, saturation, lightness] array' do
      to_hsl(@white).should == [0, 0, 1]
      to_hsl(@black).should == [0, 0, 0]
      to_hsl(@red).should   == [0, 1, 0.5]
      to_hsl(@blue).should  == [240, 1, 0.5]
      to_hsl(@green).should == [120, 1, 0.5]
    end

    it 'should optionally include the alpha channel in the returned array' do
      to_hsl(@white, true).should          == [0, 0, 1, 255]
      to_hsl(@black, true).should          == [0, 0, 0, 255]
      to_hsl(@red, true).should            == [0, 1, 0.5, 255]
      to_hsl(@blue, true).should           == [240, 1, 0.5, 255]
      to_hsl(@green, true).should          == [120, 1, 0.5, 255]
      to_hsl(@opaque, true)[3].should      == 255
      to_hsl(@fully_transparent, true)[3].should == 0
    end
  end

  describe 'conversion to other formats' do
    it 'should convert the individual color values back correctly' do
      to_truecolor_bytes(@opaque).should == [10, 100, 150]
      to_truecolor_alpha_bytes(@non_opaque).should == [10, 100, 150, 100]
    end
  end

  describe '#compose' do

    it 'should use the foregorund color as is when the background color is fully transparent' do
      compose(@non_opaque, @fully_transparent).should == @non_opaque
    end

    it 'should use the foregorund color as is when an opaque color is given as foreground color' do
      compose(@opaque, @white).should == @opaque
    end

    it 'should use the background color as is when a fully transparent pixel is given as foreground color' do
      compose(@fully_transparent, @white).should == @white
    end

    it 'should compose pixels correctly with both algorithms' do
      compose_quick(@non_opaque, @white).should   == 0x9fc2d6ff
      compose_precise(@non_opaque, @white).should == 0x9fc2d6ff
    end
  end

  describe '#decompose_alpha' do
    it 'should decompose the alpha channel correctly' do
      decompose_alpha(0x9fc2d6ff, @opaque, @white).should == 0x00000064
    end

    it 'should return fully transparent if the background channel matches the resulting color' do
      decompose_alpha(0xabcdefff, 0xff000000, 0xabcdefff).should == 0x00
    end

    it 'should return fully opaque if the background channel matches the mask color' do
      decompose_alpha(0xff000000, 0xabcdefff, 0xabcdefff).should == 0xff
    end

    it 'should return fully opaque if the resulting color matches the mask color' do
      decompose_alpha(0xabcdefff, 0xabcdefff, 0xffffffff).should == 255
    end
  end

  describe '#blend' do
    it 'should blend colors correctly' do
      blend(@opaque, @black).should == 0x05324bff
    end

    it 'should not matter what color is used as foreground, and what as background' do
      blend(@opaque, @black).should == blend(@black, @opaque)
    end
  end

  describe '#euclidean_distance_rgba' do
    subject { euclidean_distance_rgba(color_a, color_b) }

    context 'with white and black' do
      let(:color_a) { @white }
      let(:color_b) { @black }

      it { should == Math.sqrt(195_075) } # sqrt(255^2 * 3)
    end

    context 'with black and white' do
      let(:color_a) { @black }
      let(:color_b) { @white }

      it { should == Math.sqrt(195_075) } # sqrt(255^2 * 3)
    end

    context 'with the same colors' do
      let(:color_a) { @white }
      let(:color_b) { @white }

      it { should == 0 }
    end
  end
end
