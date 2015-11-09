/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */


#include "seatest.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsImage.h"

#include "jansson.h"

SEATEST_FIXTURE(assets)
{
    SEATEST_FIXTURE_ENTRY(asset_simpleText);
    SEATEST_FIXTURE_ENTRY(asset_simpleImage);
    SEATEST_FIXTURE_ENTRY(asset_subscribers);
    SEATEST_FIXTURE_ENTRY(asset_liveUpdate);
}

static int pumpTillLoaded(int timeoutMs)
{
    int startTime = platform_getMilliseconds();

    while (loom_asset_queryPendingLoads())
    {
        loom_asset_pump();

        if (platform_getMilliseconds() - startTime > timeoutMs)
        {
            return 0;
        }
    }

    return 1;
}


SEATEST_TEST(asset_simpleText)
{
    loom_asset_initialize(".");

    loom_asset_preload("test.txt");

    // Wait till it's loaded.
    assert_true(pumpTillLoaded(5000));

    // Grab 'er!
    const char *textAsset = (const char *)loom_asset_lock("test.txt", LATText, 0);

    // Print it?
    assert_string_equal("Loom Test.", textAsset);

    loom_asset_unlock("test.txt");

    // Flush it.
    loom_asset_flush("test.txt");

    // We should not be able to lock it now.
    textAsset = (const char *)loom_asset_lock("test.txt", LATText, 0);

    assert_true(textAsset == NULL);

    if (textAsset)
    {
        loom_asset_unlock("test.txt");
    }

    loom_asset_shutdown();
}

SEATEST_TEST(asset_simpleImage)
{
    loom_asset_initialize(".");

    loom_asset_preload("test.jpg");

    // Wait till it's loaded.
    assert_true(pumpTillLoaded(5000));

    // Grab 'er!
    loom_asset_image_t *imageAsset = (loom_asset_image_t *)loom_asset_lock("test.jpg", LATImage, 1);

    assert_true(imageAsset != NULL);
    if (imageAsset)
    {
        assert_true(imageAsset->width > 0);
        assert_true(imageAsset->height > 0);
    }

    loom_asset_unlock("test.jpg");

    // Flush it.
    loom_asset_flush("test.jpg");

    // Shut down.
    loom_asset_shutdown();
}

static int testFireCount = 0;
static void assetSubscriptionTestCallback(void *payload, const char *name)
{
    testFireCount++;
}


SEATEST_TEST(asset_subscribers)
{
    testFireCount = 0;

    loom_asset_initialize(".");

    // We don't even need to load a file for this to work properly.
    // Just subscribe and fire the notification.
    assert_int_equal(1, loom_asset_subscribe("!test", assetSubscriptionTestCallback, NULL, 0));

    loom_asset_notifySubscribers("!test");
    assert_int_equal(1, testFireCount);

    assert_int_equal(1, loom_asset_unsubscribe("!test", assetSubscriptionTestCallback, NULL));

    loom_asset_shutdown();
}

SEATEST_TEST(asset_liveUpdate)
{
    testFireCount = 0;

    loom_asset_initialize(".");

    // Subscribe to an asset.
    loom_asset_subscribe("test.txt", assetSubscriptionTestCallback, NULL, 0);
    assert_int_equal(0, testFireCount);

    // Grab 'er!
    loom_asset_lock("test.txt", LATText, 1);
    loom_asset_unlock("test.txt");

    // Should have seen a fire.
    assert_int_equal(1, testFireCount);

    // Now, reload all!
    loom_asset_reloadAll();

    // Wait till it's done.
    assert_true(pumpTillLoaded(5000));

    // Should have seen another fire from the reload.
    assert_int_equal(2, testFireCount);

    loom_asset_shutdown();

    // Old: Should have seen another fire from the implicit flushAll.
    // the implicit flushAll doesn't fire anymore while shutting down.
    assert_int_equal(2, testFireCount);
}
