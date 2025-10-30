<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('procrastination_alerts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('habit_id')->constrained()->onDelete('cascade');
            $table->integer('days_delayed')->default(0);
            $table->enum('severity', ['info', 'warning', 'critical'])->default('info');
            $table->text('message');
            $table->boolean('is_read')->default(false);
            $table->timestamp('sent_at');
            $table->timestamps();
            
            $table->index(['user_id', 'is_read', 'created_at']);
        });

        Schema::create('procrastination_patterns', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('habit_id')->constrained()->onDelete('cascade');
            $table->integer('total_delays')->default(0);
            $table->integer('max_delay_days')->default(0);
            $table->float('avg_delay_days')->default(0);
            $table->integer('completion_rate')->default(100);
            $table->enum('pattern_type', ['good', 'warning', 'danger'])->default('good');
            $table->timestamps();
            
            $table->unique(['user_id', 'habit_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('procrastination_patterns');
        Schema::dropIfExists('procrastination_alerts');
    }
};