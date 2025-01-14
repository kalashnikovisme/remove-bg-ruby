# frozen_string_literal: true

RSpec.describe RemoveBg::ImageComposer do
  before { RemoveBg::Configuration.reset }

  let(:alpha_file) { instance_double(File, "alpha") }
  let(:color_file) { instance_double(File, "color") }
  let(:destination_path) { instance_double(Pathname, "Destination path") }

  context "when using MiniMagick" do
    before { RemoveBg::Configuration.configuration.image_processor = :minimagick }

    it "uses MiniMagick by default" do
      require "image_processing/mini_magick"

      processing_spy = spy_on_image_processing(ImageProcessing::MiniMagick)

      perform_composition

      expect(processing_spy).to have_received(:call).with(destination: destination_path)
    end
  end

  context "when using Vips" do
    before { RemoveBg::Configuration.configuration.image_processor = :vips }

    it "uses Vips" do
      require "image_processing/vips"

      processing_spy = spy_on_image_processing(ImageProcessing::Vips)

      perform_composition

      expect(processing_spy).to have_received(:call).with(destination: destination_path)
    end
  end

  context "when configured with an unknown processor" do
    before { RemoveBg::Configuration.configuration.image_processor = :foo }

    it "raises an error" do
      expect { perform_composition }
        .to raise_exception(RemoveBg::Error, "Unsupported image processor: :foo")
    end
  end

  context "when not configured" do
    before { RemoveBg::Configuration.configuration.image_processor = nil }

    it "raises an error" do
      expect { perform_composition }
        .to raise_exception(RemoveBg::Error, "Please configure an image processor to use image composition")
    end
  end

  describe "::detect_image_processor" do
    let(:binary_detector) { instance_double(Proc, "binary_detector", call: false) }

    let(:detected) do
      described_class.detect_image_processor(detector: binary_detector)
    end

    it "can detect Imagemagick" do
      allow(binary_detector).to receive(:call).with("magick").and_return(true)

      expect(detected).to eq :minimagick
    end

    it "can detect Graphicsmagick" do
      allow(binary_detector).to receive(:call).with("gm").and_return(true)

      expect(detected).to eq :minimagick
    end

    it "can detect Vips" do
      allow(binary_detector).to receive(:call).with("vips").and_return(true)

      expect(detected).to eq :vips
    end

    it "returns nil if there are no matches" do
      expect(detected).to be_nil
    end
  end

  private

  def spy_on_image_processing(klass)
    spy(klass.to_s).tap do |processing_spy| # rubocop:disable RSpec/VerifiedDoubles
      allow(klass).to receive(:source).and_return(processing_spy)
    end
  end

  def perform_composition
    subject.compose(
      color_file: color_file,
      alpha_file: alpha_file,
      destination_path: destination_path
    )
  end
end
