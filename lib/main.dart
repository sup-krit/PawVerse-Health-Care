import 'package:flutter/material.dart';

import 'domain.dart';
import 'health_controller.dart';
import 'memory_repository.dart';

void main() => runApp(HealthApp(repository: MemoryHealthRepository()));

String dateLabel(DateTime value) => '${value.day}/${value.month}/${value.year}';
String timeLabel(DateTime value) =>
    '${dateLabel(value)} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

class HealthApp extends StatelessWidget {
  const HealthApp({super.key, required this.repository});
  final HealthRepository repository;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PawVerse Health Care',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfffcfbf6),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff214f43),
        primary: const Color(0xff214f43),
        surface: const Color(0xfffcfbf6),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfffcfbf6),
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    home: HealthHome(repository: repository),
  );
}

class HealthHome extends StatefulWidget {
  const HealthHome({super.key, required this.repository});
  final HealthRepository repository;
  @override
  State<HealthHome> createState() => _HealthHomeState();
}

class _HealthHomeState extends State<HealthHome> {
  late final HealthController controller = HealthController(widget.repository)
    ..load();
  int tab = 0;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> form(String kind) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntryPage(controller: controller, kind: kind),
      ),
    );
  }

  void detail(HealthRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Record detail')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text('${record.category.name} · ${dateLabel(record.date)}'),
                const SizedBox(height: 16),
                Text(
                  record.verified
                      ? 'Verified example · Read-only original'
                      : 'Owner entered · Private demo record',
                ),
                const Divider(height: 40),
                Text(
                  record.notes.isEmpty ? 'No notes recorded.' : record.notes,
                ),
                if (record.verified)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      'This original cannot be overwritten. Amendment workflow is outside this milestone.',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> revoke(ConsentGrant grant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke demo access?'),
        content: Text(
          '${grant.recipient} will no longer have access in the recipient preview.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep access'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke access'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.run(
        () => widget.repository.revoke(controller.petId, grant.id),
      );
    }
  }

  Future<void> preview(ConsentGrant grant) async {
    List<HealthRecord> records = [];
    String? denial;
    try {
      records = await widget.repository.preview(controller.petId, grant.id);
    } catch (_) {
      denial = 'Access ended. No records available.';
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Recipient preview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text('Demo only. No link or message was sent.'),
            const SizedBox(height: 16),
            if (denial != null)
              Text(denial)
            else ...[
              Text(
                'For ${grant.recipient} · ends ${timeLabel(grant.expiresAt)}',
              ),
              for (final record in records)
                ListTile(
                  title: Text(record.title),
                  subtitle: Text(record.notes),
                ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close preview'),
            ),
          ],
        ),
      ),
    );
  }

  Widget recordTile(HealthRecord record) => Card.filled(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        record.verified ? Icons.verified_outlined : Icons.description_outlined,
      ),
      title: Text(record.title),
      subtitle: Text(
        '${dateLabel(record.date)} · ${record.category.name}\n${record.verified ? 'Verified example · Read only' : 'Owner entered · Private'}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => detail(record),
    ),
  );
  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(subtitle),
      ],
    ),
  );
  Widget empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Text(text),
  );
  List<Widget> content(HealthSnapshot data) {
    switch (tab) {
      case 0:
        final next =
            data.appointments
                .where((a) => a.status == AppointmentStatus.scheduled)
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
        return [
          heading(
            'Care, one day\nat a time.',
            '${controller.pet.name}’s health notebook',
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xff214f43),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT APPOINTMENT',
                  style: TextStyle(
                    color: Color(0xffdceda0),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  next.isEmpty ? 'Nothing scheduled' : next.first.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  next.isEmpty
                      ? 'Add an appointment when you have one.'
                      : timeLabel(next.first.date),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => setState(() => tab = 2),
                  child: const Text('Open care plan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => form('record'),
                icon: const Icon(Icons.add),
                label: const Text('Add record'),
              ),
              OutlinedButton.icon(
                onPressed: () => form('appointment'),
                icon: const Icon(Icons.event_outlined),
                label: const Text('Plan a visit'),
              ),
            ],
          ),
          heading('Recent records', 'Factual notes, kept together.'),
          if (data.records.isEmpty)
            empty('No records yet. Add the first note for this pet.'),
          ...data.records.take(3).map(recordTile),
        ];
      case 1:
        return [
          heading(
            'Health records',
            'Only ${controller.pet.name}’s records appear here.',
          ),
          FilledButton.icon(
            onPressed: () => form('record'),
            icon: const Icon(Icons.add),
            label: const Text('Add record'),
          ),
          const SizedBox(height: 16),
          if (data.records.isEmpty)
            empty('No records yet. Start with a visit or note.'),
          ...data.records.map(recordTile),
        ];
      case 2:
        return [
          heading('Care plan', 'Appointments and recorded medication slots.'),
          FilledButton.icon(
            onPressed: () => form('appointment'),
            icon: const Icon(Icons.add),
            label: const Text('Add appointment'),
          ),
          if (data.appointments.isEmpty) empty('No appointments for this pet.'),
          for (final appointment in data.appointments)
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(timeLabel(appointment.date)),
                    Text('Status: ${appointment.status.name}'),
                    if (appointment.status == AppointmentStatus.scheduled)
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: controller.saving
                                ? null
                                : () => controller.run(
                                    () => widget.repository.setAppointment(
                                      controller.petId,
                                      appointment.id,
                                      AppointmentStatus.completed,
                                    ),
                                  ),
                            child: const Text('Complete'),
                          ),
                          TextButton(
                            onPressed: controller.saving
                                ? null
                                : () => controller.run(
                                    () => widget.repository.setAppointment(
                                      controller.petId,
                                      appointment.id,
                                      AppointmentStatus.cancelled,
                                    ),
                                  ),
                            child: const Text('Cancel appointment'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          heading(
            'Medication slots',
            'Fictional schedule only. No dosage advice or reminders.',
          ),
          if (data.doses.isEmpty) empty('No medication slots recorded.'),
          for (final dose in data.doses)
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dose.label),
                    Text(timeLabel(dose.date)),
                    Text('Status: ${dose.status.name}'),
                    if (dose.status == DoseStatus.pending)
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: controller.saving
                                ? null
                                : () => controller.run(
                                    () => widget.repository.logDose(
                                      controller.petId,
                                      dose.id,
                                      DoseStatus.taken,
                                    ),
                                  ),
                            child: const Text('Taken'),
                          ),
                          TextButton(
                            onPressed: controller.saving
                                ? null
                                : () => controller.run(
                                    () => widget.repository.logDose(
                                      controller.petId,
                                      dose.id,
                                      DoseStatus.skipped,
                                    ),
                                  ),
                            child: const Text('Skipped'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ];
      default:
        return [
          heading(
            'Your choice\nto share.',
            'Select exactly which records a demo recipient can see.',
          ),
          const Text('In-app simulation only. No real access or messages.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: data.records.isEmpty ? null : () => form('share'),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Create demo share'),
          ),
          if (data.records.isEmpty)
            empty('Add a record before creating a share.'),
          if (data.grants.isEmpty)
            empty('No demo shares. Your records start private.'),
          for (final grant in data.grants)
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grant.recipient,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${grant.recordIds.length} selected records · snapshot',
                    ),
                    Text('Until ${timeLabel(grant.expiresAt)}'),
                    Text(
                      grant.revoked
                          ? 'Revoked'
                          : grant.activeAt(DateTime.now())
                          ? 'Active demo grant'
                          : 'Expired',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => preview(grant),
                          child: const Text('Recipient preview'),
                        ),
                        if (!grant.revoked)
                          TextButton(
                            onPressed: controller.saving
                                ? null
                                : () => revoke(grant),
                            child: const Text('Revoke'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'PawVerse',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Switch pet',
            enabled: !controller.saving,
            onSelected: controller.selectPet,
            itemBuilder: (_) => widget.repository.pets
                .map(
                  (p) => PopupMenuItem(
                    value: p.id,
                    child: Text('${p.name} · ${p.species}'),
                  ),
                )
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(controller.pet.name),
                  const Icon(Icons.expand_more),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xffeef2e8),
              child: const Text(
                'DEMO · Fictional data · Resets on restart',
                style: TextStyle(fontSize: 12),
              ),
            ),
            if (controller.error != null)
              MaterialBanner(
                content: Text(controller.error!),
                actions: [
                  TextButton(
                    onPressed: controller.load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            Expanded(
              child: controller.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading care records',
                      ),
                    )
                  : controller.data == null
                  ? Center(
                      child: FilledButton(
                        onPressed: controller.load,
                        child: const Text('Retry loading'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        children: content(controller.data!),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: 'Care',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            label: 'Sharing',
          ),
        ],
      ),
    ),
  );
}

class EntryPage extends StatefulWidget {
  const EntryPage({super.key, required this.controller, required this.kind});
  final HealthController controller;
  final String kind;
  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  late final List<HealthRecord> recordOptions = List.unmodifiable(
    widget.controller.data?.records ?? <HealthRecord>[],
  );
  final key = GlobalKey<FormState>();
  final title = TextEditingController(), notes = TextEditingController();
  RecordCategory category = RecordCategory.note;
  late DateTime date = widget.kind == 'record'
      ? DateTime.now()
      : DateTime.now().add(const Duration(days: 1));
  final Set<String> selected = {};
  bool consent = false, busy = false;
  String? error;
  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: widget.kind == 'record'
          ? DateTime(2000)
          : DateTime(now.year, now.month, now.day),
      lastDate: widget.kind == 'record' ? now : DateTime(now.year + 5),
    );
    if (day == null || !mounted) return;
    DateTime chosen = day;
    if (widget.kind != 'record') {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(date),
      );
      if (time == null || !mounted) return;
      chosen = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    }
    setState(() {
      date = chosen;
      consent = false;
    });
  }

  Future<void> save() async {
    if (!key.currentState!.validate() || busy) return;
    if (widget.kind == 'share' && (selected.isEmpty || !consent)) {
      setState(() => error = 'Select at least one record and confirm consent.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final c = widget.controller;
    final ok = await c.run(
      () => switch (widget.kind) {
        'record' => c.repository.addRecord(
          c.petId,
          title.text,
          category,
          date,
          notes.text,
        ),
        'appointment' => c.repository.addAppointment(c.petId, title.text, date),
        _ => c.repository.share(c.petId, title.text, selected, date, consent),
      },
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        busy = false;
        error = c.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(switch (widget.kind) {
        'record' => 'Add record',
        'appointment' => 'Add appointment',
        _ => 'Create demo share',
      }),
    ),
    body: SafeArea(
      child: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('For ${widget.controller.pet.name} · Demo only'),
            const SizedBox(height: 20),
            TextFormField(
              controller: title,
              maxLength: 120,
              enabled: !busy,
              onChanged: (_) {
                if (widget.kind == 'share') {
                  setState(() => consent = false);
                }
              },
              decoration: InputDecoration(
                labelText: widget.kind == 'share'
                    ? 'Demo recipient name'
                    : 'Title',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'This field is required.'
                  : null,
            ),
            const SizedBox(height: 16),
            if (widget.kind == 'record') ...[
              DropdownButtonFormField<RecordCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: RecordCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notes,
                maxLength: 2000,
                maxLines: 3,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
            ],
            OutlinedButton.icon(
              onPressed: busy ? null : chooseDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                '${widget.kind == 'share' ? 'Access ends' : 'Date'}: ${widget.kind == 'record' ? dateLabel(date) : timeLabel(date)}',
              ),
            ),
            if (widget.kind == 'share') ...[
              const SizedBox(height: 20),
              const Text(
                'Select records. Later additions are not included in this demo snapshot.',
              ),
              for (final record in recordOptions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(record.title),
                  subtitle: Text(dateLabel(record.date)),
                  value: selected.contains(record.id),
                  onChanged: busy
                      ? null
                      : (value) => setState(() {
                          if (value == true) {
                            selected.add(record.id);
                          } else {
                            selected.remove(record.id);
                          }
                          consent = false;
                        }),
                ),
              const Divider(),
              Text(
                'Preview: ${selected.length} records for ${title.text.trim().isEmpty ? 'the recipient above' : title.text.trim()}, until ${timeLabel(date)}.',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I confirm this recipient, selected records and expiry for this demo.',
                ),
                value: consent,
                onChanged: busy
                    ? null
                    : (value) => setState(() => consent = value ?? false),
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(
                busy
                    ? 'Saving…'
                    : widget.kind == 'share'
                    ? 'Confirm demo share'
                    : 'Save',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
