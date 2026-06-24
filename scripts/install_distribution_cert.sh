#!/bin/bash
# install_distribution_cert.sh
# Nach dem Download des Zertifikats von developer.apple.com dieses Script ausführen
#
# USAGE: ./scripts/install_distribution_cert.sh ~/Downloads/distribution.cer

set -e

CERT_FILE="${1:-}"

if [ -z "$CERT_FILE" ] || [ ! -f "$CERT_FILE" ]; then
  echo "Usage: ./scripts/install_distribution_cert.sh <Pfad zum .cer file>"
  echo "  Beispiel: ./scripts/install_distribution_cert.sh ~/Downloads/ios_distribution.cer"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KEY_FILE="$PROJECT_DIR/certs_temp/distribution.key"

echo "=== Apple Distribution Zertifikat installieren ==="
echo ""

# 1. Zertifikat in Keychain installieren
echo "1. Importiere Zertifikat in Keychain..."
security import "$CERT_FILE" -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign 2>/dev/null || \
security import "$CERT_FILE" -k login.keychain -T /usr/bin/codesign
echo "   ✅ Zertifikat importiert"

# 2. Private Key einbinden (wenn vorhanden)
if [ -f "$KEY_FILE" ]; then
  echo "2. Importiere Private Key..."
  security import "$KEY_FILE" -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign 2>/dev/null || true
  echo "   ✅ Private Key importiert"
fi

# 3. Keychain Partition List setzen (verhindert Passwort-Popups beim Build)
echo "3. Setze Keychain Partition List..."
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "" ~/Library/Keychains/login.keychain-db 2>/dev/null || true
echo "   ✅ Partition List gesetzt"

# 4. Zertifikat verifizieren
echo "4. Verifiziere installierten Zertifikat..."
CERT_CHECK=$(security find-identity -v -p codesigning 2>&1 | grep "Apple Distribution" || echo "")
if [ -n "$CERT_CHECK" ]; then
  echo "   ✅ Apple Distribution Zertifikat aktiv:"
  echo "   $CERT_CHECK"
else
  echo "   ⚠️  Zertifikat nicht gefunden. Prüfe Keychain Access manuell."
fi

echo ""
echo "=== iOS IPA Build starten ==="
echo ""
cd "$PROJECT_DIR"

# 5. Flutter IPA Build
echo "5. Building iOS IPA for TestFlight..."
flutter build ipa --release --export-options-plist ios/ExportOptions.plist 2>&1 | tail -10

# 6. IPA prüfen
IPA_PATH="build/ios/ipa/Parentpeak.ipa"
if [ -f "$IPA_PATH" ]; then
  IPA_SIZE=$(du -sh "$IPA_PATH" | awk '{print $1}')
  echo ""
  echo "✅ IPA erfolgreich erstellt: $IPA_PATH ($IPA_SIZE)"
  echo ""
  echo "=== NÄCHSTE SCHRITTE ==="
  echo "TestFlight Upload:"
  echo "  fastlane ios beta"
  echo ""
  echo "Oder manuell in Xcode Organizer:"
  echo "  open ios/Runner.xcworkspace"
  echo "  Xcode → Window → Organizer → Distribute App → TestFlight"
else
  echo "❌ IPA nicht gefunden. Prüfe Build-Log oben."
  exit 1
fi

# Cleanup temp certs
echo ""
echo "🧹 Cleanup temporäre Dateien..."
rm -rf "$PROJECT_DIR/certs_temp"
echo "   ✅ certs_temp gelöscht"
