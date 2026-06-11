import 'package:trusted_circle_demo/models/event_participation.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';

class ParticipationService {
  static final List<EventParticipation> _participations = [];

  // Frage Teilnahme an
  Future<EventParticipation> requestParticipation({
    required String eventId,
    required String userId,
  }) async {
    await Future.delayed(Duration(milliseconds: 600));

    final participation = EventParticipation(
      id: 'participation_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      userId: userId,
      requestedAt: DateTime.now(),
      status: ParticipationStatus.pending,
    );

    _participations.add(participation);
    return participation;
  }

  // Genehmige Teilnahme-Anfrage
  Future<bool> approveParticipation(String participationId) async {
    await Future.delayed(Duration(milliseconds: 400));

    try {
      final index =
          _participations.indexWhere((p) => p.id == participationId);
      if (index != -1) {
        final existing = _participations[index];
        _participations[index] = EventParticipation(
          id: existing.id,
          eventId: existing.eventId,
          userId: existing.userId,
          requestedAt: existing.requestedAt,
          approvedAt: DateTime.now(),
          status: ParticipationStatus.approved,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Lehne Teilnahme-Anfrage ab
  Future<bool> declineParticipation(String participationId) async {
    await Future.delayed(Duration(milliseconds: 400));

    try {
      final index =
          _participations.indexWhere((p) => p.id == participationId);
      if (index != -1) {
        final existing = _participations[index];
        _participations[index] = EventParticipation(
          id: existing.id,
          eventId: existing.eventId,
          userId: existing.userId,
          requestedAt: existing.requestedAt,
          declinedAt: DateTime.now(),
          status: ParticipationStatus.declined,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Hole Partizipation-Details
  Future<EventParticipation?> getParticipation(String participationId) async {
    await Future.delayed(Duration(milliseconds: 200));

    try {
      return _participations.firstWhere((p) => p.id == participationId);
    } catch (e) {
      return null;
    }
  }

  // Prüfe ob User teilnehmer eines Events ist
  Future<EventParticipation?> getParticipationByUserAndEvent({
    required String userId,
    required String eventId,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));

    try {
      return _participations.firstWhere((p) =>
          p.userId == userId &&
          p.eventId == eventId &&
          p.status == ParticipationStatus.approved);
    } catch (e) {
      return null;
    }
  }

  // Hole alle genehmigten Teilnehmer eines Events
  Future<List<EventParticipation>> getApprovedParticipantsForEvent(
      String eventId) async {
    await Future.delayed(Duration(milliseconds: 300));

    return _participations
        .where((p) =>
            p.eventId == eventId &&
            p.status == ParticipationStatus.approved)
        .toList();
  }
}
