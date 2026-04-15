<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('categorias', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('nombre', 100)->unique();
            $table->string('icono', 50)->nullable();
            $table->string('color', 7)->nullable();
            $table->text('descripcion')->nullable();
            $table->boolean('activo')->default(true);
            $table->timestampTz('created_at')->default(DB::raw('NOW()'));
            $table->timestampTz('updated_at')->nullable();
        });

        // Insertar categorías iniciales
        DB::table('categorias')->insert([
            ['nombre' => 'Personas', 'icono' => 'person', 'color' => '#FF6B6B', 'descripcion' => 'Personas perdidas o desaparecidas'],
            ['nombre' => 'Mascotas', 'icono' => 'pets', 'color' => '#4ECDC4', 'descripcion' => 'Perros, gatos y otras mascotas'],
            ['nombre' => 'Documentos', 'icono' => 'description', 'color' => '#45B7D1', 'descripcion' => 'Identificaciones, pasaportes, licencias'],
            ['nombre' => 'Electrónicos', 'icono' => 'smartphone', 'color' => '#96CEB4', 'descripcion' => 'Teléfonos, laptops, tablets, etc.'],
            ['nombre' => 'Vehículos', 'icono' => 'directions_car', 'color' => '#FFEAA7', 'descripcion' => 'Autos, motos, bicicletas'],
            ['nombre' => 'Ropa/Accesorios', 'icono' => 'checkroom', 'color' => '#DDA0DD', 'descripcion' => 'Ropa, bolsas, joyas, etc.'],
            ['nombre' => 'Llaves', 'icono' => 'vpn_key', 'color' => '#F39C12', 'descripcion' => 'Llaves de casa, auto, oficina'],
            ['nombre' => 'Otros', 'icono' => 'category', 'color' => '#95A5A6', 'descripcion' => 'Otros objetos no categorizados'],
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categorias');
    }
};



