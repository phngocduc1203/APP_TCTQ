<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('habits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('ten_thoi_quen');
            $table->text('mo_ta')->nullable();
            $table->string('diem');
            $table->string('repeat_type')->default('daily');
            $table->string('repeat_data')->nullable();
            $table->integer('duration_days')->default(1);
            $table->integer('completed_days')->default(0);
            $table->boolean('completed')->default(false);
            $table->date('completedDate')->nullable();
            $table->date('start_date')->nullable();
            $table->boolean('is_challenge')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('habits');
    }
};