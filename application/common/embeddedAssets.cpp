// There are a few mandatory resources. We include them directly in the
// game binary to simplify distribution/development. You can also use this
// path to embed your own assets if you so desire.
// 

#include "embeddedAssets.h"
#include "loom/common/assets/assets.h"

extern "C"
{
	void supplyEmbeddedAssets()
	{
	   loom_asset_supply("assets/tile.png", (void*)______sdk_assets_tile_png, ______sdk_assets_tile_png_size);
	   loom_asset_supply("assets/fps_images.png", (void*)______sdk_assets_fps_images_png, ______sdk_assets_fps_images_png_size);
	   loom_asset_supply("assets/fps_imageshd.png", (void*)______sdk_assets_fps_imageshd_png, ______sdk_assets_fps_imageshd_png_size);
	   loom_asset_supply("assets/fps_images-ipadhd.png", (void*)______sdk_assets_fps_images_ipadhd_png, ______sdk_assets_fps_images_ipadhd_png_size);
	   loom_asset_supply("$splashAssets.png", (void*)splashAssets_png, splashAssets_png_size);
	}	
}
