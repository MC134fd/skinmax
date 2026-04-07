# Skinmax - App Store Submission Checklist

## Before Submission
- [ ] Test on physical device (iPhone)
- [ ] Test camera permissions flow (first launch)
- [ ] Test photo library permissions flow
- [ ] Test notification permissions flow
- [ ] Verify all 8 skin metrics display correctly
- [ ] Verify food scanning and nutrition parsing
- [ ] Test offline behavior (no network)
- [ ] Test with no data (empty states)
- [ ] Test delete all data flow
- [ ] Verify 90-day data retention works
- [ ] Test landscape is blocked (portrait only)

## App Store Connect
- [ ] Create App Store Connect listing
- [ ] Upload app icon (1024x1024, no alpha, no rounded corners)
- [ ] Add screenshots for iPhone 15 Pro Max (6.7")
- [ ] Add screenshots for iPhone SE (4.7") if supporting
- [ ] Fill in app description (see AppStoreMetadata.swift)
- [ ] Add keywords (see AppStoreMetadata.swift)
- [ ] Set category to Health & Fitness
- [ ] Set age rating (likely 4+)
- [ ] Add privacy policy URL
- [ ] Add support URL
- [ ] Fill in App Privacy details (camera, photos used locally)

## Privacy & Compliance
- [ ] Privacy policy hosted and accessible
- [ ] Terms of service hosted and accessible
- [ ] App Privacy nutrition labels filled in App Store Connect
- [ ] Disclose camera usage purpose
- [ ] Disclose photo library usage purpose
- [ ] Note: OpenAI API sends images for processing - disclose in privacy policy

## Build & Archive
- [ ] Set version number (1.0.0)
- [ ] Set build number (1)
- [ ] Select "Any iOS Device" as build target
- [ ] Product > Archive
- [ ] Validate archive in Organizer
- [ ] Upload to App Store Connect
- [ ] Submit for review
